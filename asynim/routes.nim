import school/routes
## Импортируйте роуты остальных подпроектов
import views

template baseRoutes*() =
  router baseRoutes:
    get "/":
      resp indexView()
    get "/api/v1/":
      baseApiView()
    error Http403:
      deniedView()
    error Http404:
      notFoundView()

template getRoutes*() =
  baseRoutes()
  schoolRoutes()
  ## Не забудьте зарегистрировать роуты здесь
