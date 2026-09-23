# spec: v_usuario_publico

Objetivo: permitir reportes de usuarios sin exponer credenciales.

Columnas: id, nombre, apellido, mail, celular, rol, created_at.
Filtro: eliminado = FALSE.
Seguridad: omitir usuario.contrasena y otorgar SELECT sobre la vista sin otorgar SELECT sobre usuario.
Criterio de aceptacion: equivalencia bidireccional con EXCEPT y permiso directo sobre la tabla denegado.
