PRAGMA foreign_keys = ON;

CREATE TABLE producto_cache (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL CHECK (length(trim(fecha_copia)) > 0)
) STRICT;

CREATE TABLE snapshot_servidor (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL CHECK (length(trim(fecha_copia)) > 0)
) STRICT;

CREATE TABLE snapshot_servidor_import (
    id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    precio_centavos TEXT NOT NULL,
    stock TEXT NOT NULL,
    disponible TEXT NOT NULL CHECK (disponible IN ('t', 'f')),
    eliminado TEXT NOT NULL CHECK (eliminado IN ('t', 'f')),
    fecha_copia TEXT NOT NULL
) STRICT;

CREATE TABLE pedido_borrador (
    id_local TEXT PRIMARY KEY,
    usuario TEXT NOT NULL CHECK (length(trim(usuario)) > 0),
    forma_pago TEXT NOT NULL CHECK (
        forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')
    ),
    fecha TEXT NOT NULL CHECK (length(trim(fecha)) > 0)
) STRICT;

CREATE TABLE item_borrador (
    id_local TEXT NOT NULL,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL
        CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador (id_local),
    FOREIGN KEY (producto_id) REFERENCES producto_cache (id)
) STRICT;

CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY,
    id_local TEXT NOT NULL,
    estado TEXT NOT NULL CHECK (
        estado IN (
            'PENDIENTE',
            'CONFLICTO',
            'RECHAZADO',
            'SIMULADO_APROBADO'
        )
    ),
    motivo TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador (id_local)
) STRICT;
