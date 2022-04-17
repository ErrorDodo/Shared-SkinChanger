local http = require "gamesense/http"

-- https://ipwhois.io/documentation
http.get("http://ipwhois.app/json/" ,function(success, response)
  if not success or response.status ~= 200 then
    print("failed")
      return
    end
    data = json.parse(response.body)
    print(data.continent)
    print(data.ip)
end)

