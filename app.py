import re
from urllib.request import urlopen
import dramatiq
from dramatiq.brokers.redis import RedisBroker
from molten import App, QueryParam, Route, Response, HTTP_302
import dramatiq_dashboard
import os
from dotenv import load_dotenv
load_dotenv()


REDIS_URL = "redis://{host}:{port}/0".format(host=os.environ.get('DRAMATIQ_REDIS_HOST', default="localhost"), port=os.environ.get('DRAMATIQ_REDIS_PORT', default=6379))
broker = RedisBroker(url=REDIS_URL)
dramatiq.set_broker(broker)


HREF_RE = re.compile('href="(https?://[^"]+)"')

@dramatiq.actor(max_retries=1)
def crawl(uri):
    crawl.logger.info("Crawling %r...", uri)
    with urlopen(uri) as response:
        if "text/html" not in response.headers.get("content-type", ""):
            return

        for match in HREF_RE.finditer(response.read().decode("utf-8")):
            match_uri = match.group(1)
            if broker.client.sismember("crawl_seen", match_uri):
                continue

            crawl.send(match_uri)
            broker.client.sadd("crawl_seen", match_uri)

    crawl.send(uri)
    return "Message sent!"


def redirect_to_drama():
    return Response(status=HTTP_302, headers={"Location": "/drama/"})


app = App(routes=[
    Route("/", redirect_to_drama, method="GET")
])

dashboard_middleware = dramatiq_dashboard.make_wsgi_middleware("/drama")
app = dashboard_middleware(app)