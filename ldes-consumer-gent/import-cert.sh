#!/bin/sh
# Import the Gent LDES certificate into Java keystore

echo "Importing SSL certificate for ldes.stad.gent..."

# Copy default cacerts to temp location
cp $JAVA_HOME/lib/security/cacerts /tmp/cacerts
chmod 644 /tmp/cacerts

# Import the certificate
keytool -import -alias gent-ldes -keystore /tmp/cacerts -file /tmp/gent-ldes.crt -storepass changeit -noprompt

echo "Certificate imported successfully"

# Start the application with custom truststore
exec java -Djavax.net.ssl.trustStore=/tmp/cacerts -Djavax.net.ssl.trustStorePassword=changeit -cp /ldio/ldio-application.jar -Dloader.path=/ldio/lib/ org.springframework.boot.loader.launch.PropertiesLauncher
