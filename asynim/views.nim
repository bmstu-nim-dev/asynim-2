import asyncdispatch
import htmlgen, json
import constants
import utils

template indexView*(): untyped =
  await getContent(
    title("Главная страница Asynim"),
    mainHeading=h1("Главная страница Asynim"),
    await getFileData("templates/index.html")
  )

template baseApiView*() =
  resp %*{
    "shop": ApiPrefix & "/shop",
    "shelter": ApiPrefix & "/shelter",
    "school": ApiPrefix & "/school"
  }

template notFoundView*() =
  resp await getContent(
    title("404"),
    h1("Страница не найдена :(", class="text-danger"),
    `div`(
      a("На главную", href="/", class="btn btn-outline-light"),
      class="text-center"
    )
  )

template deniedView*() =
  resp await getContent(
    title("403"),
    h1("Действие запрещено", class="text-danger"),
    `div`(
      a("На главную", href="/", class="btn btn-outline-light"),
      class="text-center"
    )
  )
