fx_version("cerulean")
game("gta5")

author("Skull Network Italia")
description("Loadscreen ufficiale Skull Network Italia")
version("1.0.1")

loadscreen("index.html")
loadscreen_cursor("yes")

client_script("client.lua")

files({
  "index.html",
  "style.css",
  "script.js",
  "assets/intro.mp4",
  "assets/intro.mp3",
})
