# hdbpp-barman-reporting

- [hdbpp-barman-reporting](#hdbpp-barman-reporting)
  - [Dependencies](#Dependencies)
  - [Usage](#Usage)
  - [Deployment](#Deployment)
    - [Direct](#Direct)
      - [Logs](#Logs-1)
  - [Configuration](#Configuration)
  - [License](#License)

Barman, as the backup system is a central element of the hdbpp archive system. It is therefore of crucial importance to monitor it to ensure that it is running properly.

This script is meant to be used as barman pre and post backup hooks. It will measure the time taken for the backup, the size of the backup and any other metrics that might be of use. It will then report these values to the hdbpp cluster reporting tool through its rest api.

The same script is to be used as both pre and post backup hook.

## Dependencies

Following Python dependencies are required for direct deployment:

* pyyaml

## Usage

The script has a simple command line help menu with some helpful utilities. To view:

```bash
./hdbpp_barman.py --help
```

## Deployment

The script must be deployed directly on the machine running the barman backup system.

### Direct

If deploying directly, the Python requirements must be met:

```
pip install -r requirements.txt
```

Once setup, the script and its setup files must be installed. Copy the main script into a system path:

```bash
cp hdbpp_barman.py /usr/local/bin
```

Edit the barman config file to execute the script as pre and post backup script:

```bash
pre_backup_script = hdbpp_barman.py
post_backup_script = hdbpp_barman.py
```

Finally copy the example config into place and customize it:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_barman.conf /etc/hdb/hdbpp_barman.conf
```

#### Logs

The direct deploy cron file redirects logging to syslog. Therefore a simple grep for 'hdbpp-barman-report' in the syslog will show when and what the result was of the last run.

## Configuration

The example config file setup/hdbpp_barman.conf is commented for easy customisation.

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.
