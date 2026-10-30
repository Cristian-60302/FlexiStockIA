import os

from flask import Flask, jsonify, request
from flask_cors import CORS  
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv


load_dotenv()

app = Flask(__name__)
CORS(app)  


def get_connection():
    return psycopg2.connect(
        host="ep-raspy-scene-b4o7810q-pooler.c-6.us-east-2.aws.neon.tech",
        database="neondb",
        user="neondb_owner",
        password="npg_VZ5WOEoTB2CA",
        sslmode="require",
        channel_binding="require"
    )
##

# =========================================================
# ENDPOINT 1 - LOGIN
# POST /login
# =========================================================

@app.route("/login", methods=["POST"])
def login():

    try:
        data = request.get_json()

        correo = data.get("correo")
        password = data.get("password")

        if not correo or not password:
            return jsonify({
                "error": "Correo y contraseña son obligatorios"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                u.id_usuario,
                u.nombre,
                u.correo,
                u.password,
                e.id_empresa,
                e.nombre AS empresa
            FROM usuarios u
            INNER JOIN empresas e
                ON u.id_empresa = e.id_empresa
            WHERE u.correo = %s
        """, (correo,))

        usuario = cursor.fetchone()

        cursor.close()
        conn.close()

        if usuario is None:
            return jsonify({
                "error": "Correo o contraseña incorrectos"
            }), 401

        if password != usuario["password"]:
            return jsonify({
                "error": "Correo o contraseña incorrectos"
            }), 401

        # No devolver la contraseña
        del usuario["password"]

        return jsonify({
            "mensaje": "Login exitoso",
            "usuario": usuario
        })

    except Exception as e:

        print(e)

        return jsonify({
            "error": "Error interno del servidor"
        }), 500


# =========================================================
# ENDPOINT 2 - CONSULTAR PRODUCTOS
# GET /productos?id_empresa=1
# =========================================================

@app.route("/productos", methods=["GET"])
def obtener_productos():

    try:

        id_empresa = request.args.get("id_empresa")

        if not id_empresa:
            return jsonify({
                "error": "Debe enviar id_empresa"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                p.id_producto,
                p.nombre,
                p.descripcion,
                p.marca,
                c.nombre AS categoria
            FROM productos p
            INNER JOIN categorias c
                ON p.id_categoria = c.id_categoria
            WHERE p.id_empresa = %s
            ORDER BY p.id_producto
        """, (id_empresa,))

        productos = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({
            "empresa": id_empresa,
            "cantidad": len(productos),
            "productos": productos
        })

    except Exception as e:

        print(e)

        return jsonify({
            "error": "Error consultando productos"
        }), 500

# =========================================================
# ENDPOINT 3 - AGREGAR OBJETO AL INVENTARIO
# POST /inventario
# =========================================================

@app.route("/inventario", methods=["POST"])
def agregar_inventario():

    try:

        data = request.get_json()

        id_producto = data.get("id_producto")
        codigo = data.get("codigo")
        estado = data.get("estado", "Disponible")
        ubicacion = data.get("ubicacion")

        if not id_producto or not codigo:
            return jsonify({
                "error": "id_producto y codigo son obligatorios"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            INSERT INTO inventario
            (
                id_producto,
                codigo,
                estado,
                ubicacion
            )
            VALUES (%s, %s, %s, %s)
            RETURNING *
        """, (
            id_producto,
            codigo,
            estado,
            ubicacion
        ))

        objeto = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "mensaje": "Objeto agregado correctamente",
            "objeto": objeto
        }), 201

    except psycopg2.errors.UniqueViolation:

        return jsonify({
            "error": "El código del objeto ya existe"
        }), 409

    except psycopg2.errors.ForeignKeyViolation:

        return jsonify({
            "error": "El producto indicado no existe"
        }), 400

    except Exception as e:

        print(e)

        return jsonify({
            "error": "Error agregando objeto al inventario"
        }), 500


# =========================================================
# ENDPOINT 4 - RESUMEN DEL INVENTARIO
# GET /inventario/resumen?id_empresa=1
# =========================================================

@app.route("/inventario/resumen", methods=["GET"])
def resumen_inventario():

    try:

        id_empresa = request.args.get("id_empresa")

        if not id_empresa:
            return jsonify({
                "error": "Debe enviar id_empresa"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                p.id_producto,
                p.nombre AS producto,

                COUNT(i.id_objeto) AS total,

                COUNT(*) FILTER (
                    WHERE i.estado = 'Disponible'
                ) AS disponibles,

                COUNT(*) FILTER (
                    WHERE i.estado = 'Dañado'
                ) AS danados,

                COUNT(*) FILTER (
                    WHERE i.estado = 'Prestado'
                ) AS prestados,

                COUNT(*) FILTER (
                    WHERE i.estado = 'Vendido'
                ) AS vendidos

            FROM productos p

            LEFT JOIN inventario i
                ON p.id_producto = i.id_producto

            WHERE p.id_empresa = %s

            GROUP BY
                p.id_producto,
                p.nombre

            ORDER BY p.nombre
        """, (id_empresa,))

        resumen = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({
            "empresa": id_empresa,
            "resumen": resumen
        })

    except Exception as e:

        print(e)

        return jsonify({
            "error": "Error generando resumen"
        }), 500


# =========================================================
# ENDPOINT 5 - ACTUALIZAR OBJETO
# PUT /inventario/<id>
# =========================================================

@app.route("/inventario/<int:id_objeto>", methods=["PUT"])
def actualizar_inventario(id_objeto):

    try:

        data = request.get_json()

        estado = data.get("estado")
        ubicacion = data.get("ubicacion")

        if not estado and not ubicacion:
            return jsonify({
                "error": "Debe enviar estado o ubicacion"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            UPDATE inventario

            SET
                estado = COALESCE(%s, estado),
                ubicacion = COALESCE(%s, ubicacion)

            WHERE id_objeto = %s

            RETURNING *
        """, (
            estado,
            ubicacion,
            id_objeto
        ))

        objeto = cursor.fetchone()

        if objeto is None:

            cursor.close()
            conn.close()

            return jsonify({
                "error": "Objeto no encontrado"
            }), 404

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "mensaje": "Objeto actualizado correctamente",
            "objeto": objeto
        })

    except Exception as e:

        print(e)

        return jsonify({
            "error": "Error actualizando inventario"
        }), 5003
# =========================================================
# ENDPOINT 6 - CREAR PRODUCTO
# POST /productos
# =========================================================

@app.route("/productos", methods=["POST"])
def crear_producto():

    try:
        data = request.get_json()

        id_empresa = data.get("id_empresa")
        nombre = data.get("nombre")
        descripcion = data.get("descripcion")
        marca = data.get("marca")
        id_categoria = data.get("id_categoria")

        if not id_empresa or not nombre:
            return jsonify({
                "error": "id_empresa y nombre son obligatorios"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            INSERT INTO productos
            (
                id_empresa,
                nombre,
                descripcion,
                marca,
                id_categoria
            )
            VALUES (%s, %s, %s, %s, %s)
            RETURNING *
        """, (
            id_empresa,
            nombre,
            descripcion,
            marca,
            id_categoria
        ))

        producto = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "mensaje": "Producto creado correctamente",
            "producto": producto
        }), 201

    except psycopg2.errors.ForeignKeyViolation:
        return jsonify({
            "error": "La empresa o la categoría indicada no existen"
        }), 400

    except Exception as e:
        print(e)
        return jsonify({
            "error": "Error creando el producto"
        }), 500
    # =========================================================
# ENDPOINT 7 - CREAR CATEGORÍA
# POST /categorias
# =========================================================

@app.route("/categorias", methods=["POST"])
def crear_categoria():

    try:
        data = request.get_json()

        id_empresa = data.get("id_empresa")
        nombre = data.get("nombre")
        descripcion = data.get("descripcion")

        if not id_empresa or not nombre:
            return jsonify({
                "error": "id_empresa y nombre son obligatorios"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            INSERT INTO categorias
            (
                id_empresa,
                nombre,
                descripcion
            )
            VALUES (%s, %s, %s)
            RETURNING *
        """, (
            id_empresa,
            nombre,
            descripcion
        ))

        categoria = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "mensaje": "Categoría creada correctamente",
            "categoria": categoria
        }), 201

    except psycopg2.errors.ForeignKeyViolation:
        return jsonify({
            "error": "La empresa indicada no existe"
        }), 400

    except Exception as e:
        print(e)
        return jsonify({
            "error": "Error creando la categoría"
        }), 500



# =========================================================
# ENDPOINT 8- REGISTRO DE USUARIO
# POST /registro
# =========================================================

@app.route("/registro", methods=["POST"])
def registrar_usuario():
    try:
        data = request.get_json()

        nombre = data.get("nombre")
        correo = data.get("correo")
        password = data.get("password")
        id_empresa = data.get("id_empresa", 1)  # Por defecto asigna empresa 1 si no se envía

        if not nombre or not correo or not password:
            return jsonify({
                "error": "Nombre, correo y contraseña son obligatorios"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Insertar nuevo usuario
        cursor.execute("""
            INSERT INTO usuarios (nombre, correo, password, id_empresa)
            VALUES (%s, %s, %s, %s)
            RETURNING id_usuario, nombre, correo, id_empresa
        """, (nombre, correo, password, id_empresa))

        nuevo_usuario = cursor.fetchone()
        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "mensaje": "Usuario registrado exitosamente",
            "usuario": nuevo_usuario
        }), 201

    except psycopg2.errors.UniqueViolation:
        return jsonify({
            "error": "El correo electrónico ya está registrado"
        }), 409

    except Exception as e:
        print(e)
        return jsonify({
            "error": "Error interno al registrar usuario"
        }), 500


# =========================================================
# ENDPOINT 9 - CONSULTAR PRODUCTO POR ID
# GET /productos/<id_producto>
# =========================================================

@app.route("/productos/<int:id_producto>", methods=["GET"])
def obtener_producto(id_producto):

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                p.id_producto,
                p.id_empresa,
                p.nombre,
                p.descripcion,
                p.marca,
                p.id_categoria,
                c.nombre AS categoria
            FROM productos p
            INNER JOIN categorias c
                ON p.id_categoria = c.id_categoria
            WHERE p.id_producto = %s
        """, (id_producto,))

        producto = cursor.fetchone()

        if producto is None:
            return jsonify({
                "error": "Producto no encontrado"
            }), 404

        return jsonify({
            "mensaje": "Producto consultado correctamente",
            "producto": producto
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando el producto"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()



# =========================================================
# ENDPOINT 10 - ACTUALIZAR PRODUCTO
# PUT /productos/<id_producto>
# =========================================================

@app.route("/productos/<int:id_producto>", methods=["PUT"])
def actualizar_producto(id_producto):

    conn = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict) or not data:
            return jsonify({
                "error": "Debe enviar un JSON con los campos a actualizar"
            }), 400

        campos_permitidos = {
            "nombre",
            "descripcion",
            "marca",
            "id_categoria"
        }

        if not set(data.keys()).issubset(campos_permitidos):
            return jsonify({
                "error": "Hay campos no permitidos para actualizar"
            }), 400

        if not any(campo in data for campo in campos_permitidos):
            return jsonify({
                "error": "Debe enviar al menos un campo para actualizar"
            }), 400

        if "nombre" in data and (
            not isinstance(data["nombre"], str)
            or not data["nombre"].strip()
        ):
            return jsonify({
                "error": "El nombre no puede estar vacío"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            UPDATE productos
            SET
                nombre = CASE WHEN %s THEN %s ELSE nombre END,
                descripcion = CASE WHEN %s THEN %s ELSE descripcion END,
                marca = CASE WHEN %s THEN %s ELSE marca END,
                id_categoria = CASE WHEN %s THEN %s ELSE id_categoria END
            WHERE id_producto = %s
            RETURNING *
        """, (
            "nombre" in data, data.get("nombre"),
            "descripcion" in data, data.get("descripcion"),
            "marca" in data, data.get("marca"),
            "id_categoria" in data, data.get("id_categoria"),
            id_producto
        ))

        producto = cursor.fetchone()

        if producto is None:
            conn.rollback()
            return jsonify({
                "error": "Producto no encontrado"
            }), 404

        conn.commit()

        return jsonify({
            "mensaje": "Producto actualizado correctamente",
            "producto": producto
        }), 200

    except psycopg2.errors.ForeignKeyViolation:
        if conn:
            conn.rollback()

        return jsonify({
            "error": "La categoría indicada no existe"
        }), 400

    except Exception as e:
        if conn:
            conn.rollback()

        print(e)

        return jsonify({
            "error": "Error actualizando el producto"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


# =========================================================
# ENDPOINT 11 - CONSULTAR CATEGORÍAS
# GET /categorias?id_empresa=1
# =========================================================

@app.route("/categorias", methods=["GET"])
def obtener_categorias():

    conn = None
    cursor = None

    try:
        id_empresa = request.args.get("id_empresa")

        if not id_empresa:
            return jsonify({
                "error": "Debe enviar id_empresa"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                c.id_categoria,
                c.id_empresa,
                c.nombre,
                c.descripcion
            FROM categorias c
            WHERE c.id_empresa = %s
            ORDER BY c.id_categoria
        """, (id_empresa,))

        categorias = cursor.fetchall()

        return jsonify({
            "empresa": id_empresa,
            "cantidad": len(categorias),
            "categorias": categorias
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando las categorías"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# =========================================================
# ENDPOINT 12 - CONSULTAR CATEGORÍA POR ID
# GET /categorias/<id_categoria>
# =========================================================

@app.route("/categorias/<int:id_categoria>", methods=["GET"])
def obtener_categoria(id_categoria):

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                c.id_categoria,
                c.id_empresa,
                c.nombre,
                c.descripcion
            FROM categorias c
            WHERE c.id_categoria = %s
        """, (id_categoria,))

        categoria = cursor.fetchone()

        if categoria is None:
            return jsonify({
                "error": "Categoría no encontrada"
            }), 404

        return jsonify({
            "mensaje": "Categoría consultada correctamente",
            "categoria": categoria
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando la categoría"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# =========================================================
# ENDPOINT 13 - ACTUALIZAR CATEGORÍA
# PUT /categorias/<id_categoria>
# =========================================================

@app.route("/categorias/<int:id_categoria>", methods=["PUT"])
def actualizar_categoria(id_categoria):

    conn = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict) or not data:
            return jsonify({
                "error": "Debe enviar un JSON con los campos a actualizar"
            }), 400

        campos_permitidos = {"nombre", "descripcion"}

        if not set(data.keys()).issubset(campos_permitidos):
            return jsonify({
                "error": "Solo puede actualizar nombre y descripcion"
            }), 400

        if not any(campo in data for campo in campos_permitidos):
            return jsonify({
                "error": "Debe enviar al menos un campo para actualizar"
            }), 400

        if "nombre" in data:
            if not isinstance(data["nombre"], str) or not data["nombre"].strip():
                return jsonify({
                    "error": "El nombre no puede estar vacío"
                }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            UPDATE categorias
            SET
                nombre = CASE
                    WHEN %s THEN %s
                    ELSE nombre
                END,
                descripcion = CASE
                    WHEN %s THEN %s
                    ELSE descripcion
                END
            WHERE id_categoria = %s
            RETURNING id_categoria, id_empresa, nombre, descripcion
        """, (
            "nombre" in data,
            data.get("nombre"),
            "descripcion" in data,
            data.get("descripcion"),
            id_categoria
        ))

        categoria = cursor.fetchone()

        if categoria is None:
            conn.rollback()

            return jsonify({
                "error": "Categoría no encontrada"
            }), 404

        conn.commit()

        return jsonify({
            "mensaje": "Categoría actualizada correctamente",
            "categoria": categoria
        }), 200

    except Exception as e:
        if conn:
            conn.rollback()

        print(e)

        return jsonify({
            "error": "Error actualizando la categoría"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if conn:
            conn.close()

# =========================================================
# ENDPOINT 14 - CONSULTAR INVENTARIO
# GET /inventario?id_empresa=1
# =========================================================

@app.route("/inventario", methods=["GET"])
def obtener_inventario():

    conn = None
    cursor = None

    try:
        id_empresa = request.args.get("id_empresa")

        if not id_empresa:
            return jsonify({
                "error": "Debe enviar id_empresa"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                i.id_objeto,
                i.id_producto,
                p.nombre AS producto,
                p.marca,
                i.codigo,
                i.estado,
                i.ubicacion
            FROM inventario i
            INNER JOIN productos p
                ON i.id_producto = p.id_producto
            WHERE p.id_empresa = %s
            ORDER BY i.id_objeto
        """, (id_empresa,))

        objetos = cursor.fetchall()

        return jsonify({
            "empresa": id_empresa,
            "cantidad": len(objetos),
            "inventario": objetos
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando el inventario"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if conn:
            conn.close()

# =========================================================
# ENDPOINT 15 - CONSULTAR OBJETO POR ID
# GET /inventario/<id_objeto>
# =========================================================

@app.route("/inventario/<int:id_objeto>", methods=["GET"])
def obtener_objeto_inventario(id_objeto):

    conn = None
    cursor = None

    try:
        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                i.id_objeto,
                i.id_producto,
                p.nombre AS producto,
                p.descripcion,
                p.marca,
                p.id_empresa,
                i.codigo,
                i.estado,
                i.ubicacion
            FROM inventario i
            INNER JOIN productos p
                ON i.id_producto = p.id_producto
            WHERE i.id_objeto = %s
        """, (id_objeto,))

        objeto = cursor.fetchone()

        if objeto is None:
            return jsonify({
                "error": "Objeto de inventario no encontrado"
            }), 404

        return jsonify({
            "mensaje": "Objeto consultado correctamente",
            "objeto": objeto
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando el objeto del inventario"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if conn:
            conn.close()


# =========================================================
# ENDPOINT 16 - REGISTRAR MOVIMIENTO
# POST /movimientos
# =========================================================

@app.route("/movimientos", methods=["POST"])
def registrar_movimiento():

    conn = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return jsonify({
                "error": "Debe enviar un JSON válido"
            }), 400

        id_producto = data.get("producto_id")
        tipo = data.get("tipo")
        cantidad = data.get("cantidad")
        motivo = data.get("motivo")

        if id_producto is None or not tipo or cantidad is None:
            return jsonify({
                "error": "producto_id, tipo y cantidad son obligatorios"
            }), 400

        tipos_permitidos = ["ENTRADA", "SALIDA", "AJUSTE"]

        if tipo not in tipos_permitidos:
            return jsonify({
                "error": "Tipo inválido. Use ENTRADA, SALIDA o AJUSTE"
            }), 400

        if not isinstance(cantidad, int) or isinstance(cantidad, bool) or cantidad <= 0:
            return jsonify({
                "error": "La cantidad debe ser un entero mayor que cero"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Verificar que el producto exista
        cursor.execute("""
            SELECT id_producto, nombre
            FROM productos
            WHERE id_producto = %s
        """, (id_producto,))

        producto = cursor.fetchone()

        if producto is None:
            return jsonify({
                "error": "El producto indicado no existe"
            }), 404

        # Registrar el movimiento
        cursor.execute("""
            INSERT INTO movimientos
            (
                id_producto,
                tipo,
                cantidad,
                motivo
            )
            VALUES (%s, %s, %s, %s)
            RETURNING *
        """, (
            id_producto,
            tipo,
            cantidad,
            motivo
        ))

        movimiento = cursor.fetchone()

        conn.commit()

        return jsonify({
            "mensaje": "Movimiento registrado correctamente",
            "producto": producto["nombre"],
            "movimiento": movimiento
        }), 201

    except psycopg2.errors.ForeignKeyViolation:
        if conn:
            conn.rollback()

        return jsonify({
            "error": "El producto indicado no existe"
        }), 400

    except Exception as e:
        if conn:
            conn.rollback()

        print(e)

        return jsonify({
            "error": "Error registrando el movimiento"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if conn:
            conn.close()

# =========================================================
# ENDPOINT 17 - CONSULTAR MOVIMIENTO
# GET /movimientos?id_empresa=1
# =========================================================

@app.route('/movimientos', methods=['GET'])
def obtener_movimientos():
    conn = get_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    try:
        # Empresa obligatoria para separar los datos
        id_empresa = request.args.get('id_empresa')

        if not id_empresa:
            return jsonify({
                "error": "Debes enviar el id_empresa"
            }), 400

        try:
            id_empresa = int(id_empresa)
        except ValueError:
            return jsonify({
                "error": "El id_empresa debe ser un numero entero"
            }), 400

        # Consulta base
        query = """
            SELECT
                m.*,
                p.nombre AS nombre_producto
            FROM movimientos m
            INNER JOIN productos p
                ON m.id_producto = p.id_producto
            WHERE p.id_empresa = %s
        """

        params = [id_empresa]

        # Filtro opcional por producto
        id_producto = request.args.get('id_producto')

        if id_producto:
            try:
                id_producto = int(id_producto)
            except ValueError:
                return jsonify({
                    "error": "El id_producto debe ser un numero entero"
                }), 400

            query += " AND m.id_producto = %s"
            params.append(id_producto)

        # Filtro opcional por tipo
        tipo = request.args.get('tipo')

        if tipo:
            tipo = tipo.upper()

            if tipo not in ['ENTRADA', 'SALIDA', 'AJUSTE']:
                return jsonify({
                    "error": "Tipo de movimiento no valido"
                }), 400

            query += " AND m.tipo = %s"
            params.append(tipo)

        # Ordenar del movimiento mas reciente al mas antiguo
        query += " ORDER BY m.fecha DESC"

        cur.execute(query, tuple(params))

        movimientos = cur.fetchall()

        return jsonify({
            "total": len(movimientos),
            "movimientos": movimientos
        }), 200

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500

    finally:
        cur.close()
        conn.close()


# =========================================================
# ENDPOINT 18 - ALERTAS DE STOCK BAJO
# GET /alertas/stock-bajo?id_empresa=1
#     /alertas/stock-bajo?id_empresa=<Id empresa>&limite=<Numero del limite>
# =========================================================

@app.route("/alertas/stock-bajo", methods=["GET"])
def alertas_stock_bajo():

    conn = None
    cursor = None

    try:
        id_empresa = request.args.get("id_empresa")
        limite = request.args.get("limite", 5)

        if not id_empresa:
            return jsonify({
                "error": "Debe enviar id_empresa"
            }), 400

        try:
            id_empresa = int(id_empresa)
            limite = int(limite)

            if id_empresa <= 0 or limite < 0:
                raise ValueError

        except ValueError:
            return jsonify({
                "error": "id_empresa debe ser positivo y limite no puede ser negativo"
            }), 400

        conn = get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT
                p.id_producto,
                p.nombre AS producto,
                p.marca,

                COUNT(i.id_objeto) FILTER (
                    WHERE i.estado = 'Disponible'
                ) AS unidades_disponibles,

                COUNT(i.id_objeto) AS total_objetos

            FROM productos p

            LEFT JOIN inventario i
                ON p.id_producto = i.id_producto

            WHERE p.id_empresa = %s

            GROUP BY
                p.id_producto,
                p.nombre,
                p.marca

            HAVING COUNT(i.id_objeto) FILTER (
                WHERE i.estado = 'Disponible'
            ) <= %s

            ORDER BY unidades_disponibles ASC
        """, (id_empresa, limite))

        alertas = cursor.fetchall()

        return jsonify({
            "empresa": id_empresa,
            "limite_stock": limite,
            "total_alertas": len(alertas),
            "alertas": alertas
        }), 200

    except Exception as e:
        print(e)

        return jsonify({
            "error": "Error consultando las alertas de stock"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if conn:
            conn.close()



# =========================================================
# RUTA PRINCIPAL
# =========================================================

@app.route("/", methods=["GET"])
def inicio():

    return jsonify({
        "mensaje": "API de Inventarios funcionando",
        "endpoints": [
            "POST /login",
            "GET /productos?id_empresa=1",
            "POST /inventario",
            "GET /inventario/resumen?id_empresa=1",
            "PUT /inventario/<id>"
        ]
    })
# =========================================================
# INICIAR SERVIDOR
# =========================================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=3000,
        debug=True
    )
