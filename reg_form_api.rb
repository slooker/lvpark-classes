require 'RMagick'
require 'uuid'
require 'sinatra'
require 'pp'
require 'json'

set :bind, '0.0.0.0'

def generateForm(data)

	i = Magick::ImageList.new('CC-Reg.jpg')

	canvas = Magick::ImageList.new
	canvas.new_image(1700, 2200, Magick::TextureFill.new(i))

	text = Magick::Draw.new
	text.pointsize = 32

	text.annotate(canvas, 610, 40, 230, 600, data["firstName"]) #firstName
	text.annotate(canvas, 610, 40, 978, 600, data["lastName"]) #lastName
	text.annotate(canvas, 370, 40, 210, 677, data["primaryPhone"]) # primaryPhone
	if (data["secondaryPhone"]) 
		text.annotate(canvas, 370, 40, 677, 677, data["secondaryPhone"]) # secondaryPhone
	end
	text.annotate(canvas, 370, 40, 1176, 677, data["emergencyContact"]) # emergencyContact
	text.annotate(canvas, 650, 40, 195, 755, data["address1"]) # address1
	if (data["address2"])
		text.annotate(canvas, 160, 40, 900, 755, data["address2"]) # address2
	end
	text.annotate(canvas, 290, 40, 1110, 755, data["city"]) # city
	text.annotate(canvas, 115, 40, 1450, 755, data["zip"]) # zip
	text.annotate(canvas, 1390, 40, 165, 828, data["email"]) # email

	if (data["participants"][0]) 
		text.annotate(canvas, 615, 40, 308, 945, data["participants"][0]["name"]) # Participant 1 Name
		text.annotate(canvas, 500, 40, 1060, 945, data["participants"][0]["dob"]) # Participan 1 DoB
	end

	if (data["participants"][1])
		text.annotate(canvas, 615, 40, 308, 1023, data["participants"][1]["name"]) # Participant 2 Name
		text.annotate(canvas, 500, 40, 1060, 1023, data["participants"][1]["dob"]) # Participan 2 DoB
	end

	if (data["participants"][2])
		text.annotate(canvas, 615, 40, 308, 1098, data["participants"][2]["name"]) # Participant 2 Name
		text.annotate(canvas, 500, 40, 1060, 1098, data["participants"][2]["dob"]) # Participan 2 DoB
	end

	if (data["special"])
		text.annotate(canvas, 700, 40, 838, 1175, data["special"]) # Special accomodations
	end

	text.pointsize = 22

	totalFee = 0
	if (data["classes"][0])
		text.annotate(canvas, 205, 30, 90, 1267, data["classes"][0]["code"]) # Activity Code 1
		text.annotate(canvas, 390, 30, 305, 1267, data["classes"][0]["className"]) # Activity Name 1
		text.annotate(canvas, 215, 30, 705, 1267, data["classes"][0]["session"]) # Session Number 1
		text.annotate(canvas, 440, 30, 930, 1267, data["classes"][0]["participantName"]) # Participant Name 1
		text.annotate(canvas, 185, 30, 1380, 1267, data["classes"][0]["fee"]) # Fee 1
		totalFee += data["classes"][0]["fee"].to_i
	end

	if (data["classes"][1])
		myClass = data["classes"][1]
		pp myClass
		text.annotate(canvas, 205, 30, 90, 1307, myClass["code"]) # Activity Code 2
		text.annotate(canvas, 390, 30, 305, 1307, myClass["className"]) # Activity Name 2
		text.annotate(canvas, 215, 30, 705, 1307, myClass["session"]) # Session Number 2
		text.annotate(canvas, 440, 30, 930, 1307, myClass["participantName"]) # Participant Name 2
		text.annotate(canvas, 185, 30, 1380, 1307, myClass["fee"]) # Fee 2
		totalFee += data["classes"][1]["fee"].to_i
	end

	if (data["classes"][2])
		text.annotate(canvas, 205, 30, 90, 1347, data["classes"][2]["code"]) # Activity Code 3
		text.annotate(canvas, 390, 30, 305, 1347, data["classes"][2]["className"]) # Activity Name 3
		text.annotate(canvas, 215, 30, 705, 1347, data["classes"][2]["session"]) # Session Number 3
		text.annotate(canvas, 440, 30, 930, 1347, data["classes"][2]["participantName"]) # Participant Name 3
		text.annotate(canvas, 185, 30, 1380, 1347, data["classes"][2]["fee"]) # Fee 3
		totalFee += data["classes"][2]["fee"].to_i

	end

	if (data["classes"][3])
		text.annotate(canvas, 205, 30, 90, 1387, data["classes"][3]["code"]) # Activity Code 3
		text.annotate(canvas, 390, 30, 305, 1387, data["classes"][3]["className"]) # Activity Name 3
		text.annotate(canvas, 215, 30, 705, 1387, data["classes"][3]["session"]) # Session Number 3
		text.annotate(canvas, 440, 30, 930, 1387, data["classes"][3]["participantName"]) # Participant Name 3
		text.annotate(canvas, 185, 30, 1380, 1387, data["classes"][3]["fee"]) # Fee 3
		totalFee += data["classes"][3]["fee"].to_i
	end
	
	text.annotate(canvas, 185, 30, 1380, 1390, totalFee.to_s) # Total Fees

	text.annotate(canvas, 350, 30, 125, 1485, "#{data['firstName']} #{data["lastName"]}") # I, state your name, etc etc.

	text.annotate(canvas, 295, 30, 845, 1440, data["licenseNo"]) # Drivers License number
	text.annotate(canvas, 245 , 30, 1295, 1440, data["licenseState"]) # Drivers License State

	uuid = UUID.new
	filename = "#{uuid.generate}.gif"
	canvas.write(filename)
	return filename
end


get '/image/:filename' do
	content_type 'image/gif'
	img = Magick::Image.read(params['filename'])[0]
	img.format = 'gif'
	img.to_blob
end

post '/getRegForm' do
	content_type :json
	params = JSON.parse(request.env["rack.input"].read)
	filename = generateForm(params)
	url = "http://thisapp.is-slick.com:4567/image/#{filename}"
	{ "imageUrl" => url }.to_json
end
