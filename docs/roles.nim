runnableExamples:
  import roles

  assert roles.admin == 3
  assert roles.moderator == 2

  var user: User
  user.name = "Banned man"
  user.roles = @[3,2,1]

  assert roles.admin in user.roles
  assert roles.moderator in user.roles
  assert roles.approved in user.roles

const
  admin* = 3
  moderator = 2
  approved = 1
  user = 0
  frozen = -1