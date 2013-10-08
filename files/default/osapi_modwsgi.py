from nova.openstack.common import log as logging
from nova import config
from paste import deploy

config_files = ['/etc/nova/api-paste.ini', '/etc/nova/nova.conf']
config.parse_args([], default_config_files=config_files)

LOG = logging.getLogger(__name__)
logging.setup("nova")

conf = config_files[0]
name = "osapi_compute"

options = deploy.appconfig('config:%s' % conf, name=name)

application = deploy.loadapp('config:%s' % conf, name=name)
