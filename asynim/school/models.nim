import norm/[sqlite, model]

type
  Subjects* = enum
    NONE, История, География, Математика, Биология
  Person* = ref object of Model
    firstname*: string
    lastname*: string
    birthDate*: int64
  Director* = ref object of Person
  Teacher* = ref object of Person
    subject*: Subjects
  Student* = ref object of Person
    classNum*: int
    classLet*: string


proc `$`*(p: Person): string = p.firstname & " " & p.lastname

proc newDirector*(firstname: string = "", lastname: string = "",
                birthDate: int64 = 0): Director =
  Director(
    firstname: firstname,
    lastname: lastname,
    birthDate: birthDate
  )

proc newTeacher*(firstname: string = "", lastname: string = "",
                birthDate: int64 = 0, subject: Subjects = NONE): Teacher =
  Teacher(
    firstname: firstname,
    lastname: lastname,
    birthDate: birthDate,
    subject: subject
  )

proc newStudent*(firstname: string = "", lastname: string = "",
                birthDate: int64 = 0, classNum: int = 0,
                classLet: string = "A"): Student =
  Student(
    firstname: firstname,
    lastname: lastname,
    birthDate: birthDate,
    classNum: classNum,
    classLet: classLet
  )

proc initSchool*(db: DbConn) =
  db.createTables(newDirector())
  db.createTables(newTeacher())
  db.createTables(newStudent())
