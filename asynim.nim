import jester
import norm/sqlite
import asynim/[routes]
import asynim/school/[models]
## Не забудьте подключить модели

when isMainModule:
  let dbSchool = open("asynim_school.db", "", "", "")
  let dbShelter = open("asynim_shelter.db", "", "", "")
  let dbShop = open("asynim_shop.db", "", "", "")
  dbSchool.initSchool()
  ## Инициализируйте модели аналогично школе

  getRoutes()
  settings = newSettings(port = Port(8080))

  var server = initJester(settings)
  server.register(baseRoutes.matcher)
  server.register(schoolRoutes.matcher)
  ## Не забудьте зарегистрировать эндпоинты здесь

  server.register(baseRoutes.errorHandler)
  server.serve()

  dbSchool.close()
