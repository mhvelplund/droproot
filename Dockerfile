FROM dropwizard-example

ENV ROLL_UP=droproot
ENV COLLECTOR_ADDRESS=over_ride_me:8181

COPY glowroot/glowroot.jar /glowroot.jar

# Configure central collector
CMD echo "agent.id=$ROLL_UP::$HOSTNAME" > /glowroot.properties && \
	echo "collector.address=$COLLECTOR_ADDRESS" >> /glowroot.properties && \
	java -javaagent:/glowroot.jar -jar application.jar server example.yml