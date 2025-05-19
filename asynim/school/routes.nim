import views

template schoolRoutes*() =
  router schoolRoutes:
    get "/school":
      resp schoolProjectView()
    get "/school/director":
      resp detailDirectorView()
    get "/school/director/update":
      resp await formDirectorView()
    post "/school/director/update":
      resp updateDirectorView()
    get "/school/@person/create":
      cond @"person" in ["teacher", "student"]
      resp await formPersonView(@"person")
    post "/school/@person/create":
      cond @"person" in ["teacher", "student"]
      resp createPersonView()
    get "/school/@person/@id":
      cond @"person" in ["teacher", "student"]
      resp await detailPersonView(dbSchool, @"person", @"id")
    get "/api/v1/school":
      schoolApiView()
