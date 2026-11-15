"""Copia (una sola vez) los datos de la SQLite antigua al Postgres del VPS.

Antes: primer despliegue hecho (las migraciones ya crearon las tablas) y túnel SSH abierto (guía 03, 3.7).
Uso:   python deploy/migrar_sqlite_a_postgres.py <ruta/agenda.db>
La URL de Postgres se pide oculta para que no quede en el historial (o se toma de DATABASE_URL).
Necesita las dependencias de backend/requirements.txt.
"""
import getpass
import os
import sys

from sqlalchemy import Boolean, MetaData, create_engine, func, select, text

TABLAS = ['users', 'calendar_events', 'sticky_notes', 'monthly_covers']  # en orden de claves foráneas


def contar(conn, tabla):
    return conn.execute(select(func.count()).select_from(tabla)).scalar()


def migrar(sqlite_path, pg_url):
    if not os.path.isfile(sqlite_path):
        raise SystemExit(f'No existe {sqlite_path}')
    origen = create_engine(f'sqlite:///file:{os.path.abspath(sqlite_path)}?mode=ro&uri=true')  # solo lectura
    destino = create_engine(pg_url)
    meta_o, meta_d = MetaData(), MetaData()
    meta_o.reflect(origen, only=TABLAS)
    meta_d.reflect(destino, only=TABLAS)

    with origen.connect() as o, destino.begin() as d:  # una transacción: o se copia todo o nada
        for nombre in TABLAS:
            if contar(d, meta_d.tables[nombre]):
                raise SystemExit(f'La tabla {nombre} ya tiene datos en Postgres: no se copia nada.')

        for nombre in TABLAS:
            t_o, t_d = meta_o.tables[nombre], meta_d.tables[nombre]
            booleanas = {c.name for c in t_d.columns if isinstance(c.type, Boolean)}
            filas = []
            for r in o.execute(select(t_o)).mappings():
                # SQLite guarda los booleanos como 0/1 y Postgres no los acepta como boolean
                filas.append({k: (bool(v) if k in booleanas and v is not None else v)
                              for k, v in r.items() if k in t_d.columns})
            if filas:
                d.execute(t_d.insert(), filas)
            # Las filas llegan con su id: el contador de Postgres debe seguir después del mayor
            d.execute(text(f"SELECT setval(pg_get_serial_sequence('{nombre}', 'id'), "
                           f"COALESCE((SELECT MAX(id) FROM {nombre}), 0) + 1, false)"))
            copiadas = contar(d, t_d)
            assert copiadas == contar(o, t_o) == len(filas), f'{nombre}: conteos distintos'
            print(f'{nombre}: {copiadas} filas copiadas (origen {len(filas)})')
    print('Listo: conteos iguales en todas las tablas.')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    migrar(sys.argv[1], os.environ.get('DATABASE_URL') or getpass.getpass('URL de Postgres (oculta): '))
