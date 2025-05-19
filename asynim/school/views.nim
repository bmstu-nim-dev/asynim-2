import asyncdispatch
import htmlgen, strutils, sequtils, json
import norm/[sqlite]
import models
import ../[constants, utils]

template schoolProjectView*(): untyped =
  let card = await getFileData("templates/card.html")
  let table = await getFileData("templates/table.html")
  let director = dbSchool.selectAll(Director)[^1]
  let teachers = dbSchool.selectAll(Teacher)
  let students = dbSchool.selectAll(Student)
  var content = `div`(
    "{{ director }}{{ teachers }}{{ student }}",
    class="d-flex flex-column align-items-center"
  )
  content = content.multiReplace(
    ("{{ director }}", card.multiReplace(
      ("{{ title }}", $director),
      ("{{ subtitle }}", director.birthDate.toStr),
      ("{{ description }}", "Директор нашей школы"),
      ("{{ link }}", "/school/director"),
      ("{{ api_link }}", ApiPrefix & "/school/director")
    )),
    ("{{ teachers }}", table.multiReplace(
      ("{{ thead }}", tr(
          th("Имя"),
          th("Дата рождения"),
          th("Предмет"),
          th("Детали")
        )
      ),
      ("{{ rows }}", teachers.mapIt(
        tr(
          td($it),
          td(it.birthDate.toStr),
          td($(it.subject)),
          td(
            span(
              a("Подробнее", href="/school/teacher/" & $it.id, class="text-decoration-none", target="_blank"),
              " / ",
              a("API", href= ApiPrefix & "/school/teacher/" & $it.id, class="text-decoration-none", target="_blank")
            )
          )
        )).join())
    )),
    ("{{ student }}", table.multiReplace(
      ("{{ thead }}", tr(
        th("Имя"),
        th("Дата рождения"),
        th("Класс"),
        th("Детали")
      )),
      ("{{ rows }}", students.mapIt(
        tr(
          td($it),
          td(it.birthDate.toStr),
          td("$1-$2" % [$(it.classNum), it.classLet]),
          td(
            span(
            a(
              "Подробнее",
              href="/school/student/" & $it.id,
              class="text-decoration-none",
              target="_blank"
            ),
            " / ",
            a(
              "API",
              href= ApiPrefix & "/school/student/" & $it.id,
              class="text-decoration-none",
              target="_blank"
            ))
          )
        )
      ).join())
    ))
  )
  await getContent(
    title("Проект Школа"),
    h1(
      "Страница проекта " &
      span("&laquo;Школа&raquo;", class="text-warning")
    ),
    content
  )

proc detailPersonView*(db: DbConn, person, id: string): Future[string] {.async.} =
  let card = await getFileData("templates/card.html")
  var content: string
  if person == "teacher":
    var item = db.select(Teacher, "Teacher.id = ?", id.parseInt)[0]
    content = card.multiReplace(
      ("{{ title }}", $item),
      ("{{ subtitle }}", item.birthDate.toStr),
      ("{{ description }}", "Преподаватель предмета '$1'" % $(item.subject)),
      ("{{ link }}", "#"),
      ("{{ api_link }}", ApiPrefix & "/school/$1/$2" % [person, id])
    )
  elif person == "student":
    var item = db.select(Student, "Student.id = ?", id.parseInt)[0]
    content = card.multiReplace(
      ("{{ title }}", $item),
      ("{{ subtitle }}", item.birthDate.toStr),
      ("{{ description }}", "Учится в классе '$1-$2'" % [$(item.classNum), item.classLet]),
      ("{{ link }}", "#"),
      ("{{ api_link }}", ApiPrefix & "/school/$1/$2" % [person, id])
    )
  await getContent(
    title("Информационная карта"),
    h1(
      "Карточка $1 с ID=$2" % [
        span("&laquo;$1&raquo;" % person, class="text-warning"),
        span(id, class="text-warning")
      ]
    ),
    content
  )

template detailDirectorView*(): untyped =
  let card = await getFileData("templates/card.html")
  var item = dbSchool.select(Director, "Director.id = ?", 1)[0]
  await getContent(
    title("Директор"),
    h1(
      "Информация о $1" % span("&laquo;Директоре&raquo;", class="text-warning")
    ),
    card.multiReplace(
      ("{{ title }}", $item),
      ("{{ subtitle }}", item.birthDate.toStr),
      ("{{ description }}", "Директор нашей школы"),
      ("{{ link }}", "#"),
      ("{{ api_link }}", ApiPrefix & "/school/director")
    )
  )

template updateDirectorView*(): untyped =
  let data = request.body.parseJson
  if data.hasKey("id"):
    resp Http403
  data["id"] = %1
  if data.hasKey("birthDate"):
    data["birthDate"] = %(data["birthDate"].getStr.toUnix)
  var item = data.to(Director)
  if dbSchool.exists(Director, "Director.id = ?", 1):
    dbSchool.update(item)
  else:
    dbSchool.insert(item, force=true)
  %*{"status": "OK"}

template createPersonView*(): untyped =
  let data = request.body.parseJson
  data["birthDate"] = %(data["birthDate"].getStr.toUnix)
  case @"person":
  of "teacher":
    data["id"] = %(dbSchool.count(Teacher) + 1)
    var item = data.to(Teacher)
    dbSchool.insert(item, force=true)
  of "student":
    data["id"] = %(dbSchool.count(Student) + 1)
    data["classNum"] = %(data["classNum"].getStr.parseInt)
    var item = data.to(Student)
    dbSchool.insert(item, force=true)
  %*{"status": "OK"}

proc formDirectorView*(): Future[string] {.async.} =
  let form = await getFileData("templates/form.html")
  await getContent(
    title("Обновить данные директора"),
    h1("Заполните форму чтобы обновить данные", class="text-info"),
    form.multiReplace(
      ("{{ action }}", "/school/director/update"),
      ("{{ inputs }}", `div`(
        `div`(label("Имя", class="form-label"), input(name="firstname", class="form-control"), class="mb-3"),
        `div`(label("Фамилия", class="form-label"), input(name="lastname", class="form-control"), class="mb-3"),
        `div`(label("Дата рождения", class="form-label"), input(name="birthDate", class="form-control date"), class="mb-3")
      )
      )
    )
  )

proc formPersonView*(person: string): Future[string] {.async.} =
  let form = await getFileData("templates/form.html")
  var content: string
  case person:
  of "teacher":
    content = form.multiReplace(
      ("{{ action }}", "/school/$1/create" % person),
      ("{{ inputs }}", `div`(
        `div`(label("Имя", class="form-label"), input(name="firstname", class="form-control"), class="mb-3"),
        `div`(label("Фамилия", class="form-label"), input(name="lastname", class="form-control"), class="mb-3"),
        `div`(label("Дата рождения", class="form-label"), input(name="birthDate", class="form-control date"), class="mb-3"),
        `div`(label("Предмет", class="form-label"), select(Subjects.toSeq.mapIt(option($it, value = $it)).join, name="subject", class="form-select"), class="mb-3"),
      )
      )
    )
  of "student":
    content = form.multiReplace(
      ("{{ action }}", "/school/$1/create" % person),
      ("{{ inputs }}", `div`(
        `div`(label("Имя", class="form-label"), input(name="firstname", class="form-control"), class="mb-3"),
        `div`(label("Фамилия", class="form-label"), input(name="lastname", class="form-control"), class="mb-3"),
        `div`(label("Дата рождения", class="form-label"), input(name="birthDate", class="form-control date"), class="mb-3"),
        `div`(label("Номер класса", class="form-label"), input(name="classNum", class="form-control num"), class="mb-3"),
        `div`(label("Буква класса", class="form-label"), input(name="classLet", class="form-control", maxlength="1"), class="mb-3"),
      )
      )
    )
  await getContent(
    title("Добавить " & person),
    h1("Заполните форму чтобы обновить данные", class="text-info"),
    content
  )


template schoolApiView*() =
  ## Исправьте заглушку
  ## Эндпоинт должен отдавать JsonNode:
  ## - {"director": JObject[id, lastname}
  ## - {"teacher": JArray[JObject[id, lastname]]}
  ## - {"student": JArray[JObject[id, lastname]]}
  resp %*{"message": "Заглушка API для проекта школы"}

## Реализуйте представления для API учителей, студентов и директора
## Начать с директора будет проще всего