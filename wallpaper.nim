import cgi
import httpclient
import json
import os
import osproc
import strutils
import times

let cacheDir = expandTilde("~/.cache/wallpaper/")
let position = "Marburg"
let waitTime = 10 * 60 * 1000

proc getWeatherConditionCode(position:string): int =
  let url = "http://query.yahooapis.com/v1/public/yql?q="
  let query = """select item.condition from weather.forecast
                 where woeid in (select woeid from geo.places(1)
                 where text="$#")""" % [position]
  let queryResult = parseJson(getContent(url & encodeUrl(query) & "&format=json"))
  return queryResult["query"][
                     "results"][
                     "channel"][
                     "item"][
                     "condition"][
                     "code"].getStr().parseInt()
      

proc parseWeatherConditionCode(code:int):string =
  case code
    of 0..4,23,37..39:
      return "stormy"
    of 5..8,10,17,18:
      return "freezing"
    of 9,11,12,40:
      return "rainy"
    of 13..16,41..43,46:
      return "snowy"
    of 19:
      return "dusty"
    of 20:
      return "foggy"
    of 21:
      return "hazy"
    of 22:
      return "smoky"
    of 24:
      return "windy"
    of 25,35:
      return "cold"
    of 26..30,44,45,47:
      return "cloudy"
    of 31:
      return "clear"
    of 32:
      return "sunny"
    of 33,34:
      return "fair"
    of 36:
      return "hot"
    else:
      return "boring"
    

proc getTimeDescription():tuple[time:string,weekday:string,hour:string] =
  let now = getLocalTime(getTime())
  let weekday = now.weekday
  var time = ""
  case now.hour
    of 0..6,23..24:
      time = "night"
    of 7..11:
      time = "morning"
    of 12..13:
      time = "midday"
    of 14..18:
      time = "afternoon"
    of 19..22:
      time = "evening"
    else:
      time = ""
  var h = cast[range[0..24]](now.hour)
  if now.minute > 30: h += 1
  let intToWord = ["twelve",
                   "one",
                   "two",
                   "three",
                   "four",
                   "five",
                   "six",
                   "seven",
                   "eight",
                   "nine",
                   "ten",
                   "eleven"]
  return (time,$weekday,intToWord[h mod 12])


proc getDateFact():tuple[fact:string,year:int] =
  let now = getLocalTime(getTime())
  let query = "http://numbersapi.com/$1/$2/date?json&fragment" %
              [format(now, "M"),format(now,"d")]
  let queryResult = parseJson(getContent(query))
  return (getStr(queryResult["text"]),
          cast[int](getNum(queryResult["year"])))


proc getSwansonQuote():string =
  return parseJson(getContent("http://ron-swanson-quotes.herokuapp.com/v2/quotes"))[0].getStr


proc getMessage():string =
  let message = "It was a $1 $2 $3 around $4 o'clock. As Ron Swanson would say: \"$5\""
  let now = getTimeDescription()
  # let dateFact = getDateFact()
  return message % [parseWeatherConditionCode(getWeatherConditionCode(position)),
                    now.weekday, now.time, now.hour,
                    getSwansonQuote()]


proc composeImage(message:string) =
  discard startProcess(command = "/usr/bin/convert",
                       args = ["-background", "none",
                               "-fill", "rgba(120,60,6,0.8)",
                               "-font", "Veteran-Typewriter",
                               "-pointsize", "60",
                               "-interline-spacing", "5",
                               "-rotate", "28",
                               "-blur", "10x1.2",
                               "-size", "1000x",
                               "caption:$#" % message,
                               "text.png"]).waitForExit()

  discard startProcess(command = "/usr/bin/composite",
                       args = ["-compose", "atop",
                               "-geometry", "+1150+900",
                               "text.png",
                               "wallpaper_blank.png",
                               "result.png"]).waitForExit()


proc setWallpaper(file:string) =
  discard startProcess(command = "/usr/bin/setroot",
                       args = ["-s", cacheDir / file]).waitForExit()


setCurrentDir(cacheDir)
setWallpaper("wallpaper_blank.png")
while true:
  composeImage(getMessage())
  setWallpaper("result.png")
  sleep(waitTime)
