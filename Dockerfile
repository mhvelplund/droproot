FROM dropwizard-example

COPY glowroot/glowroot.jar /glowroot.jar

# Configure central collector
CMD cp /glowroot.properties.sample /glowroot.properties && \
	echo "agent.id=droproot::$HOSTNAME" >> /glowroot.properties && \
	java -javaagent:/glowroot.jar -jar application.jar server example.yml