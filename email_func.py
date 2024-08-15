import azure.functions as func
import logging
import smtplib
import json
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


app = func.FunctionApp()
@app.service_bus_queue_trigger(arg_name="azservicebus", queue_name="",
                               connection="") 
def servicebus_trigger1(azservicebus: func.ServiceBusMessage):
    json_data = azservicebus.get_body().decode('utf-8')
    dictionay = json.loads(json_data)
    price = dictionay.get('price')
    email = dictionay.get('email')
   
   
   
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587  # or 465 for SSL
    smtp_user = 'email'
    smtp_password = ''
    to_email = email
    


    # Create the email
    msg = MIMEMultipart()
    msg['From'] = smtp_user
    msg['To'] = to_email
    msg['Subject'] = 'Male-fashion'

   

    # Email body
    body = f"""Thank you for placing order with us.\n\nYour total order amount:${price} .\n\nBest Regards,\nMale-Fashion"""
    msg.attach(MIMEText(body, 'plain'))

    # Connect to the SMTP server
    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()  # Secure the connection
        server.login(smtp_user, smtp_password)
        text = msg.as_string()
        server.sendmail(smtp_user, to_email, text)
        server.quit()
    except Exception as e:
        logging.info("Failed to send email")

    logging.info('Python ServiceBus Queue trigger processed a message: %s',
                json_data)