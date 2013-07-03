from nova.openstack.common import log as logging
from oslo.config import cfg
from paste import deploy

LOG = logging.getLogger(__name__)
logging.setup("nova")
CONF = cfg.CONF
config_files = ['/etc/nova/api-paste.ini', '/etc/nova/nova.conf']
CONF(project='nova', default_config_files=config_files)

conf = CONF.config_file[0]
name = "osapi_compute"

options = deploy.appconfig('config:%s' % conf, name=name)

application = deploy.loadapp('config:%s' % conf, name=name)
