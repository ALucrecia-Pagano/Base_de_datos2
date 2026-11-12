# FoodStore — Base de Datos II

Universidad Tecnológica Nacional, Facultad Regional Mendoza · Tecnicatura Universitaria en Programación · Comisión 4  
Profesor: Neira Sergio · Integrantes: Ávila Lucas, Liendo Mateo y Pagano Amanda

Capa de datos completa del proyecto integrador «Food Store»: relacional (PostgreSQL), documental (MongoDB) y móvil (SQLite).

## Organización

| Carpeta | Unidades | Contenido |
|---|---|---|
| [Relacional_PostgreSQL](Relacional_PostgreSQL/README.md) | 1 a 6 | Modelado, integridad y concurrencia, optimización, reportes, índices y vistas, FNBC y desnormalización, administración y seguridad, mantenimiento y recuperación |
| [NoSQL_y_Movil](NoSQL_y_Movil/README.md) | 7 y 8 | FoodStore en MongoDB y base de la tablet en SQLite con sincronización simulada |

Cada carpeta conserva su README, sus instrucciones para asistentes de IA (`AGENTS.md`) y los TPs tal como fueron entregados.

Informe de la segunda entrega del TPI: [INFORME_TPI_Segunda_Entrega.md](INFORME_TPI_Segunda_Entrega.md) (también en [PDF](INFORME_TPI_Segunda_Entrega.pdf)).

Cada carpeta funciona como la raíz de su repositorio original: cuando un documento interno dice "desde la raíz del repositorio", se refiere a `Relacional_PostgreSQL/` o a `NoSQL_y_Movil/`, según corresponda.

## Ramas

- `main`: capa de datos completa (unidades 1 a 8). Es la versión de la entrega.
- `unidades-7-8`: rama en la que se incorporaron las unidades 7 y 8 desde el repositorio [Bases-de-datos-II-NoSQL](https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL), conservando su historial; se integró a `main` mediante el pull request #4.
- La parte relacional tal como se entregó en la primera instancia queda en el commit `632ba2b`.

## Colaboración

Ver [CONTRIBUTING.md](CONTRIBUTING.md) y [AGENTS.md](AGENTS.md).
