FROM dropwizard-example

EXPOSE 4000

# HEALTHCHECK --interval=600s --timeout=1s --start-period=30s \
# 	CMD curl --fail http://localhost:8081/healthcheck || exit 1

COPY admin.json /admin.json
COPY glowroot/glowroot.jar /glowroot.jar
COPY glowroot/lib/glowroot-embedded-collector.jar /lib/glowroot-embedded-collector.jar


CMD [ "java", "-javaagent:/glowroot.jar", "-jar", "application.jar", "server", "example.yml" ]