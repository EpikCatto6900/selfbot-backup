local Info = {
    ["wsurl"]    = "wss://gateway.discord.gg/?v=10&encoding=json",
    ["token"]    = "",
    ["tojson"]   = function(tbl)
        return game:GetService("HttpService"):JSONEncode(tbl)
    end,
    ["tolua"]    = function(json)
        return game:GetService("HttpService"):JSONDecode(json)
    end,
}

local Ws = nil
local Commands = {}

function Commands:getcommand(content)
    local args = content:split(" ")
    if Commands[args[1]] then 
        return Commands[args[1]]
    end
    
    return "not found"
end 

function Commands:addCommand(name,func)
    Commands[name] = func 
end 

function Commands:not1(tab)
    local out = "" 
    for i, v in pairs(tab) do 
        if i ~= 1 then 
            out = out.." "..v  
        end 
    end 
    return out
end 

local Ops = {
    [10] = function(data)
        print("[+] Connected to Discord Gateway.")

        local payload = {
            op = 2,
            d = {
                token = Info["token"],
                intents = 53608447,
                properties = {
                    os = "linux",
                    browser = "roblox",
                    device = "roblox",
                }
            }
        }
        Ws:Send(Info["tojson"](payload))
        print("[+] Payload sent.")
    end,

    [0] = function(data)
        if data.t ~= "MESSAGE_CREATE" then 
            return 
        end 

        local author    = data.d.author
        local userId    = author.id 
        local username  = author.username 
        local content   = data.d.content 
        local command   = Commands:getcommand(content)
        
        if type(command) ~= "string" then 
            command({
                author = author,
                userId = userId,
                username = username,
                content = Commands:not1(string.split(content, " "))
            })
        end 
    end,
}

function Commands:Websocket(info)
    if info["token"] then 
        Info["token"] = info["token"]
    end 
    Ws = WebSocket.connect(Info["wsurl"])

    Ws.OnMessage:Connect(function(message)
        local success, data = pcall(Info["tolua"], message)
        if not success then
            warn(`Failed to parse json sigma: {message}`)
            return
        end

        if Ops[data.op] then
            Ops[data.op](data)
        end
    end)

    Ws.OnClose:Connect(function()
        print("[~] WebSocket has been closed...")
        print("[~] Restarting the WebSocket connection...")
        Commands:Websocket(info)
    end)

    return Ws
end

return Commands
