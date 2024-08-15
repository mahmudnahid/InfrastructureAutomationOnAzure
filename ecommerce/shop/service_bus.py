from azure.servicebus import ServiceBusClient, ServiceBusMessage
from django.conf import settings

class AzureServiceBus:
    def __init__(self):
        self.servicebus_client = ServiceBusClient.from_connection_string(
            conn_str=settings.AZURE_SERVICE_BUS_CONNECTION_STRING, 
            logging_enable=True
        )
        self.queue_name = settings.AZURE_SERVICE_BUS_QUEUE_NAME

    def send_message(self, message_content):
        with self.servicebus_client:
            sender = self.servicebus_client.get_queue_sender(queue_name=self.queue_name)
            with sender:
                message = ServiceBusMessage(message_content)
                sender.send_messages(message)
                print(f"Sent a message: {message_content}")