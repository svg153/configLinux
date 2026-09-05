Quiero revisar este ticket de Jira: <ticket_id>

- Revisa y analiza el ticket de Jira para entender el problema o la tarea.
- Usa gh para ver que repositorios podrían involucrados. Puedes revisar mis ultimas PRs activas y cerradas, si no es suficiente para identificar los repositorios, busca en la organización de GitHub por repositorios relacionados.
- Crea una carpeta en `~/REPOSITORIOS/0_PERSONAL/work/<company>/<id_ticket>`. Identifica el nombre de la empresa a partir de los ultimos ficheros editados.
  - Ahí dentro deberás crear:
    - Toda la documentación relacionada con el ticket, incluyendo un resumen del problema, los pasos para reproducirlo, cualquier información relevante de los repositorios involucrados, y un plan de acción para resolverlo. En resumen, toda la información que consideres relevante para entender el ticket y su contexto.
    - Un fichero para code-workspace con todos los repos involucrados.
- Tools a usar:
  - gh cli para revisar los repositorios y PRs relacionados.
  - jira cli, para todo lo relacionado con el ticket de Jira, incluyendo la descripción, los comentarios, el estado, etc.
