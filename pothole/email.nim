{.define: ssl.}
import std/strutils
import pothole/[conf, lib]
import smtp


proc sendEmail(config: ConfigTable, address: string, message: Message) =
  if not config.getBoolOrDefault("email", "enabled", false):
    log "sendEmail() called but email hasn't been enabled"
    log "Double check the Pothole configuration file please."
    log "Either you forgot to disable an option ([web] require_verification) or you forgot to enable another one ([email] enabled)"
    return # Return as there is nothing to do.

  let ssl = config.getStringOrDefault("email", "ssl", "true").toLower()
  var smtp: Smtp
  if ssl == "true":
    smtp = newSmtp(useSsl = true)
  else:
    smtp = newSmtp()
  
  smtp.connect(config.getString("email","host"), Port(config.getInt("email","port")))
  if ssl == "starttls":
    smtp.startTls()
  
  if config.exists("email", "user") and config.exists("email", "pass"):
    smtp.auth(
      config.getString("email", "user"),
      config.getString("email", "pass")
    )

  smtp.sendMail(
    config.getString("email", "from"),
    @[address], $(message)
  )

proc sendEmailCode*(config: ConfigTable, code, address: string) =
  if "\n" in address:
    log "Address has newlines in it. We will crash if we send this."
    log "Soooo, we're just not gonna send it."
    return

  config.sendEmail(address,
    createMessage(
      "Verification code for Pothole account",
"""
Your Pothole account has been created! 
But we do need you to verify that this email is real.

You can do this by simply going to this link:
$#
""" % [code],
      @[address], @[],
    )
  )

  
  

  





