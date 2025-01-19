const required = {
  "db": {
    "password": @= CVString
  }.toTable,
  "instance": {
    "name": @= CVString,
    "summary": @= CVString,
    "description": @= CVString,
    "uri": @= CVString,
    "email": @= CVString
  }.toTable,
}

const optional = {
  "db": {
    "host": @= "127.0.0.1:5432",
    "name": @= "pothole",
    "user": @= "pothole",
    "pool_size": @= 10
  }.toTable,
  "instance": {
    "rules": @= @[""],
    "languages": @= @["en"],
    "disguised_uri": @= "",
    "federated": @= true,
    "remote_size_limit": @= 30
  }.toTable,
  "web": {
    "show_staff": @= true,
    "show_version": @= true,
    "port": @= 3500,
    "endpoint": @= "/",
    "signin_link": @= "/auth/sign_in/",
    "signup_link": @= "/auth/sign_up/",
    "logout_link": @= "/auth/logout/",
    "whitelist_mode": @= false
  }.toTable,
  "storage": {
    "type": @= "flat",
    "uploads_folder": @= "uploads/",
    "upload_uri": @= "",
    "upload_server": @= "",
    "default_avatar_location": @= "default_avatar.webp",
    "upload_size_limit": @= 30
  }.toTable,
  "user": {
    "registrations_open": @= true,
    "require_approval": @= false,
    "require_verification": @= false,
    "max_attachments": @= 8,
    "max_chars": @= 2000,
    "max_poll_options": @= 20,
    "max_featured_tags": @= 10,
    "max_pins": @= 20
  }.toTable,
  "email": {
    "enabled": @= false,
    "host": @= "",
    "port": @= 0,
    "form": @= "",
    "ssl": @= true,
    "user": @= "",
    "pass": @= ""
  }.toTable,
  "mrf": {
    "active_builtin_policies": @= @["noop"],
    "active_custom_policies": @= @[""]
  }.toTable
}