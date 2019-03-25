# README

This is a simple setup for Docker Swarm containing a Glowroot central collector stack, and a version of the dropwizard-example instrumented with glowroot.

```bash
# Build "droproot"
docker build -t droproot .

# Deploy global collector
docker stack deploy -c infrastructure.yml infrastructure

# Deploy "droproot". Collector address should be the host IP plus the port the global collector listens for gRPC on (8181)
# Edit glowroot.properties so collector address points at the global collector, i.e. specify the host machine ip and port. 
# Example: 
#    collector.address=10.0.0.10:8181
docker stack deploy -c droproot.yml droproot
```

## Troubleshooting

This section shows the process for troubleshooting a broken stack. It assumes an error in a healthcheck for one of the services,
which prevents the service from becoming healthy after startup.

After deploying infrastructure, we run: `docker stack services infrastructure`.

```text
ID                  NAME                        MODE                REPLICAS            IMAGE                              PORTS
ei4v26g6snsx        infrastructure_cassandra    replicated          0/1                 cassandra:latest
iurmq2shu5gj        infrastructure_visualizer   replicated          0/1                 dockersamples/visualizer:stable    *:8080->8080/tcp
kjhajzrj4bwq        infrastructure_glowroot     replicated          0/1                 glowroot/glowroot-central:0.13.1   *:4000->4000/tcp, *:8181->8181/tcp
```

... everything is starting up

```text
ID                  NAME                        MODE                REPLICAS            IMAGE                              PORTS
ei4v26g6snsx        infrastructure_cassandra    replicated          1/1                 cassandra:latest
iurmq2shu5gj        infrastructure_visualizer   replicated          1/1                 dockersamples/visualizer:stable    *:8080->8080/tcp
kjhajzrj4bwq        infrastructure_glowroot     replicated          0/1                 glowroot/glowroot-central:0.13.1   *:4000->4000/tcp, *:8181->8181/tcp
```

... still waiting for glowroot collector's health check?

Run: `docker service ps infrastructure_glowroot`

```text
ID                  NAME                            IMAGE                              NODE                    DESIRED STATE       CURRENT STATE                 ERROR                              PORTS
7irvp66by5s0        infrastructure_glowroot.1       glowroot/glowroot-central:0.13.1   linuxkit-025000000001   Running             Starting about a minute ago
m9zprd1fkuhe         \_ infrastructure_glowroot.1   glowroot/glowroot-central:0.13.1   linuxkit-025000000001   Shutdown            Failed about a minute ago     "task: non-zero exit (143): do…"
uakv61j36wwb         \_ infrastructure_glowroot.1   glowroot/glowroot-central:0.13.1   linuxkit-025000000001   Shutdown            Failed 4 minutes ago          "task: non-zero exit (1)"
```

Check the state of the failed task "m9zprd1fkuhe" (`jq` filters JSON and is optional):

```bash
docker inspect $(docker inspect -f "{{.Status.ContainerStatus.ContainerID}}" m9zprd1fkuhe) | jq ".[0].State"
```

Looking at the output, we can see the output of the failed health checks (edited for brevity):

```json
{
	"Status": "exited",
	"Running": false,
	"Paused": false,
	"Restarting": false,
	"OOMKilled": false,
	"Dead": false,
	"Pid": 0,
	"ExitCode": 143,
	"Error": "",
	"StartedAt": "2019-03-24T07:35:48.4892318Z",
	"FinishedAt": "2019-03-24T07:38:52.9129612Z",
	"Health": {
		"Status": "unhealthy",
		"FailingStreak": 3,
		"Log": [
			{
				"Start": "2019-03-24T07:36:48.4191179Z",
				"End": "2019-03-24T07:36:49.0365771Z",
				"ExitCode": 6,
				"Output": "  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current\n                                 Dload  Upload   Total   Spent    Left  Speed\n\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r100 18454  100 18454    0     0  56841      0 --:--:-- --:--:-- --:--:-- 56956\n<!doctype html>\n\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <title>Glowroot</title>\n  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n\n  \n  <base href=\"/\"><script>var layout={\"central\":true,\"offlineViewer\":false,\"glowrootVersion\":\"0.13.1, built 2019-02-21 01:43:09 +0000\",\"loginEnabled\":false,\"rollupConfigs\":[{\"intervalMillis\":60000,\"viewThresholdMillis\":900000},{\"intervalMillis\":300000,\"viewThresholdMillis\":3600000},{\"intervalMillis\":1800000,\"viewThresholdMillis\":28800000},{\"intervalMillis\":14400000,\"viewThresholdMillis\":259200000}],\"rollupExpirationMillis\":[172800000,1209600000,7776000000,31536000000],\"queryAndServiceCallRollupExpirationMillis\":[172800000,604800000,2592000000,2592000000],\"profileRollupExpirationMillis\":[172800000,604800000,2592000000,2592000000],\"gaugeCollectionIntervalMillis\":5000,\"showNavbarTransaction\":true,\"showNavbarError\":true,\"showNavbarJvm\":true,\"showNavbarSyntheticMonitor\":true,\"showNavbarIncident\":true,\"showNavbarReport\":true,\"showNavbarConfig\":true,\"adminView\":true,\"adminEdit\":true,\"loggedIn\":false,\"ldap\":false,\"redirectToLogin\":false,\"defaultTimeZoneId\":\"Etc/UTC\",\"timeZoneIds\":[\"Africa/Abidjan\",\"Africa/Accra\",\"Africa/Addis_Ababa\",\"Africa/Algiers\",\"Africa/Asmara\",\"Africa/Asmera\",\"Africa/Bamako\",\"Africa/Bangui\",\"Africa/Banjul\",\"Africa/Bissau\",\"Africa/Blantyre\",\"Africa/Brazzaville\",\"Africa/Bujumbura\",\"Africa/Cairo\",\"Africa/Casablanca\",\"Africa/Ceuta\",\"Africa/Conakry\",\"Africa/Dakar\",\"Africa/Dar_es_Salaam\",\"Africa/Djibouti\",\"Africa/Douala\",\"Africa/El_Aaiun\",\"Africa/Freetown\",\"Africa/Gaborone\",\"Africa/Harare\",\"Africa/Johannesburg\",\"Africa/Juba\",\"Africa/Kampala\",\"Africa/Khartoum\",\"Africa/Kigali\",\"Africa/Kinshasa\",\"Africa/Lagos\",\"Africa/Libreville\",\"Africa/Lome\",\"Africa/Luanda\",\"Africa/Lubumbashi\",\"Africa/Lusaka\",\"Africa/Malabo\",\"Africa/Maputo\",\"Africa/Maseru\",\"Africa/Mbabane\",\"Africa/Mogadishu\",\"Africa/Monrovia\",\"Africa/Nairobi\",\"Africa/Ndjamena\",\"Africa/Niamey\",\"Africa/Nouakchott\",\"Africa/Ouagadougou\",\"Africa/Porto-Novo\",\"Africa/Sao_Tome\",\"Africa/Timbuktu\",\"Africa/Tripoli\",\"Africa/Tunis\",\"Africa/Windhoek\",\"America/Adak\",\"America/Anchorage\",\"America/Anguilla\",\"America/Antigua\",\"America/Araguaina\",\"America/Argentina/Buenos_Aires\",\"America/Argentina/Catamarca\",\"America/Argentina/ComodRivadavia\",\"America/Argentina/Cordoba\",\"America/Argentina/Jujuy\",\"America/Argentina/La_Rioja\",\"America/Argentina/Mendoza\",\"America/Argentina/Rio_Gallegos\",\"America/Argentina/Salta\",\"America/Argentina/San_Juan\",\"America/Argentina/San_Luis\",\"America/Argentina/Tucuman\",\"America/Argentina/Ushuaia\",\"America/Aruba\",\"America/Asuncion\",\"America/Atikokan\",\"America/Atka\",\"America/Bahia\",\"America/Bahia_Banderas\",\"America/Barbados\",\"America/Belem\",\"America/Belize\",\"America/Blanc-Sablon\",\"America/Boa_Vista\",\"America/Bogota\",\"America/Boise\",\"America/Buenos_Aires\",\"America/Cambridge_Bay\",\"America/Campo_Grande\",\"America/Cancun\",\"America/Caracas\",\"America/Catamarca\",\"America/Cayenne\",\"America/Cayman\",\"America/Chicago\",\"America/Chihuahua\",\"America/Coral_Harbour\",\"America/Cordoba\",\"America/Costa_Rica\",\"America/Creston\",\"America/Cuiaba\",\"America/Curacao\",\"America/Danmarkshavn\",\"America/Dawson\",\"America/Dawson_Creek\",\"America/Denver\",\"America/Detroit\",\"America/Dominica\",\"America/Edmonton\",\"America/Eirunepe\",\"America/El_Salvador\",\"America/Ensenada\",\"America/Fort_Nelson\",\"America/Fort_Wayne\",\"America/Fortaleza\",\"America/Glace_Bay\",\"America/Godthab\",\"America/Goose_Bay\",\"America/Grand_Turk\",\"America/Grenada\",\"America/Guadeloupe\",\"America/Guatemala\",\"America/Guayaquil\",\"America/Guyana\",\"America/Halifax\",\"America/Havana\",\"America/Hermosillo\",\"America/Indiana/Indianapolis\",\"America/Indiana/Knox\",\"America/Indiana/Marengo\",\"America/Indiana/Petersburg\",\"America/Indiana/Tell_City\",\"America/Indiana/Vevay\",\"America/I..."
			},
			{
				"Start": "2019-03-24T07:37:48.9739823Z",
				"End": "2019-03-24T07:37:49.1453522Z",
				"ExitCode": 6,
				"Output": "...SNIP..."
			},
			{
				"Start": "2019-03-24T07:38:49.085455Z",
				"End": "2019-03-24T07:38:49.2547482Z",
				"ExitCode": 6,
				"Output": "...SNIP..."
			}
		]
	}
}
```

Apparently the health check configured for the container returns exit code 6 instead of 0.
Code 6 is "CURLE_COULDNT_RESOLVE_HOST" ([libcurl-errors.html](https://curl.haxx.se/libcurl/c/libcurl-errors.html))

To see the healthcheck for the service, we can inspect it:

```bash
docker service inspect infrastructure_glowroot | jq ".[0].Spec.TaskTemplate.ContainerSpec.Healthcheck"
```

```json
{
	"Test": ["CMD", "curl", "--fail", "http://localhost:4000/", "||", "exit 1"],
	"Interval": 60000000000,
	"Timeout": 3000000000,
	"StartPeriod": 15000000000,
	"Retries": 3
}
```

"localhost" should be fine, so a more likely explanation is that the healthcheck is broken.
To fix it, we can change the healthcheck for glowroot in infrastructure.yml:

```yaml
healthcheck:
  test: ['CMD-SHELL', 'curl --fail http://localhost:4000/ || exit 1']
  interval: 1m
  timeout: 3s
  retries: 3
  start_period: 15s
```

Then we redeploy the stack: `docker stack deploy -c infrastructure.yml infrastructure`

After redeploying, we list the service tasks in the stack: `docker stack ps infrastructure`

```text
ID                  NAME                            IMAGE                              NODE                    DESIRED STATE       CURRENT STATE               ERROR                              PORTS
pis91x2ewe4w        infrastructure_glowroot.1       glowroot/glowroot-central:0.13.1   linuxkit-025000000001   Running             Starting 23 seconds ago
9wy4k0m4q4lw         \_ infrastructure_glowroot.1   glowroot/glowroot-central:0.13.1   linuxkit-025000000001   Shutdown            Shutdown 23 seconds ago
q8v5c8v583hk        infrastructure_visualizer.1     dockersamples/visualizer:stable    linuxkit-025000000001   Running             Running 27 minutes ago
p5w0s5nmxkzg        infrastructure_cassandra.1      cassandra:latest                   linuxkit-025000000001   Running             Running 26 minutes ago
```

Then we inspect the glowroot task "pis91x2ewe4w":

```bash
docker inspect $(docker inspect -f "{{.Status.ContainerStatus.ContainerID}}" pis91x2ewe4w) | jq ".[0].State"
```

It's starting ...

```json
{
	"Status": "running",
	"Running": true,
	"Paused": false,
	"Restarting": false,
	"OOMKilled": false,
	"Dead": false,
	"Pid": 30663,
	"ExitCode": 0,
	"Error": "",
	"StartedAt": "2019-03-24T08:02:16.3028194Z",
	"FinishedAt": "0001-01-01T00:00:00Z",
	"Health": {
		"Status": "starting",
		"FailingStreak": 0,
		"Log": []
	}
}
```

... and a little later it's up (edited for brevity):

```json
{
	"Status": "running",
	"Running": true,
	"Paused": false,
	"Restarting": false,
	"OOMKilled": false,
	"Dead": false,
	"Pid": 30663,
	"ExitCode": 0,
	"Error": "",
	"StartedAt": "2019-03-24T08:02:16.3028194Z",
	"FinishedAt": "0001-01-01T00:00:00Z",
	"Health": {
		"Status": "healthy",
		"FailingStreak": 0,
		"Log": [
			{
				"Start": "2019-03-24T08:03:16.2331547Z",
				"End": "2019-03-24T08:03:16.6008058Z",
				"ExitCode": 0,
				"Output": "...SNIP..."
			}
		]
	}
}
```

Looking at the services in infrastructure, everthing is now green: `docker stack services infrastructure`

```text
ID                  NAME                        MODE                REPLICAS            IMAGE                              PORTS
ei4v26g6snsx        infrastructure_cassandra    replicated          1/1                 cassandra:latest
iurmq2shu5gj        infrastructure_visualizer   replicated          1/1                 dockersamples/visualizer:stable    *:8080->8080/tcp
kjhajzrj4bwq        infrastructure_glowroot     replicated          1/1                 glowroot/glowroot-central:0.13.1   *:4000->4000/tcp, *:8181->8181/tcp
```
