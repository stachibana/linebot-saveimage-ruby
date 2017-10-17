require 'sinatra'
require 'line/bot'
require 'json'
require 'mini_magick'
require 'cloudinary'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV['CHANNEL_SECRET']
    config.channel_token = ENV['CHANNEL_ACCESS_TOKEN']
  }
end

post '/' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    if event['type'] == 'message' then
      if event['message']['type'] == 'image' then
        response = client.get_message_content(event.message['id'])

        # Need Config Var 'CLOUDINARY_URL' with format (API Key):(API Secret)@(Cloud name)
        image = MiniMagick::Image.read(response.body)
        imageName = SecureRandom.uuid
        image.write("tmp/#{imageName}.jpg")
        result = Cloudinary::Uploader.upload("tmp/#{imageName}.jpg")

        message = [
          {
            type: 'text',
            text: result['secure_url']
          }
        ]
        client.reply_message(event['replyToken'], message)
      end
    end
  }
  "OK"

end
