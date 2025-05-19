import asyncdispatch
import asyncfile
import htmlgen, strutils
import times
import os
import constants

proc getFileData*(filename: string): Future[string] {.async.} =
  let file = openAsync(getAppDir() / filename)
  result = await readAll(file)
  file.close()

proc getContent*(title: string = title("Asynim"),
                mainHeading: string = h1("Placeholder"),
                content: string = ""): Future[string] {.async.} =
  (await getFileData(TemplatesDir / "base.html")).multiReplace(
    ("{{ navbar }}", await getFileData(TemplatesDir / "includes" / "nav.html")),
    ("{{ title }}", title),
    ("{{ main_heading }}", mainHeading),
    ("{{ content }}", content)
  )

proc toStr*(date: int64): string = date.fromUnix.format("dd'.'MM'.'YYYY")

proc toUnix*(date: string): int64 =
  try:
    date.parse("dd'.'MM'.'YYYY").toTime.toUnix
  except TimeParseError:
    date.parse("YYYY-MM-dd").toTime.toUnix

