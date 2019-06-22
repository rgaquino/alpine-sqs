# Alpine SQS _(alpine-sqs)_

The is a fork of https://github.com/roribio/alpine-sqs removing the bundled UI that uses up to > 99% CPU.

## Install
### Pre-requisites

To be able to use this environment, please make sure you have installed the latest version of [Docker](https://docs.docker.com/engine/installation/). 

If you intend to build the environment yourself, it is recommended that you also install the latest version of [Docker Compose](https://docs.docker.com/compose/install/).

### Installation methods
You can obtain the environment in two ways; The easiest is to pull the image directly from Docker Hub. Also, you may clone this repository and build/run it using Docker Compose.
#### 1. Pulling from Docker Hub
```
docker pull rgaquino/alpine-sqs
```
#### 2. Building from scratch
```
git clone https://github.com/rgaquino/alpine-sqs.git
```
## Usage
### Running the environment
Depending on how you chose to install the environment, you can initialize it in three ways:

#### 1. `docker run` method
Use this method if you're pulling directly from Docker Hub and do not have a `docker-compose.yml` file.

```
docker run --name alpine-sqs -p 9324:9324 -d rgaquino/alpine-sqs:latest
```

Custom configuration files may be used to override default behaviors. You can mount a volume mapping the container's `/opt/custom` directory to a folder in your host machine where the custom configuration files are stored.

Providing for sake of example that in your host machine directory `/opt/alpine-sqs` you have both `elasticmq.conf` and `sqs-insight.conf` files, you can run the container with:

```
docker run --name alpine-sqs -p 9324:9324 -v /opt/alpine-sqs:/opt/custom -d rgaquino/alpine-sqs:latest
```

For any configuration file not explicitly included in the container's `/opt/custom` directory, `alpine-sqs` will fall back to using the default configuration files listed [here](https://github.com/rgaqui/alpine-sqs/tree/master/opt).

#### 2. `docker-compose up` method
If you've cloned the repository you can still take advantage of the image present in Docker Hub by running the container from the default `docker-compose.yml` file. This will pull the pre-built image from the public registry and run it with the same values stated in the previous method.

```
docker-compose up -d
```

#### 3. `docker-compose up --build` method
To build the image from scratch and then run the corresponding container, use this method.

```
docker-compose -f docker-compose.build up -d --build
```

> **Note**: To use any of the Docker Compose methods, you need to clone this repository as well as have Docker Compose installed.

>> **Note 2**: Depending on your platform, you may need to adjust how you declare mounted volumes. You can find instructions for your specific platform [here](https://github.com/roribio/alpine-sqs/wiki/Sharing-files-with-host-machine).

### Working with queues
ElasticMQ provides an Amazon-SQS compatible interface. This means you may use the AWS command-line tool, API calls and the Java SDK, to interact with local queues the same as if interacting with the actual SQS.

#### Default queue
The default configuration provisions ElasticMQ with a initial queue of the same name at run time. This allows you to start pushing messages to the queue without further configuration. 

To make use of this queue, point your client to: `http://localhost:9324/queue/default`.

#### Sending a message
To send messages to a queue you need to specify the new endpoint url and queue url along with the message payload. The following example uses the AWS CLI to send a message to the `default` queue. 

```
aws --endpoint-url http://localhost:9324 sqs send-message --queue-url http://localhost:9324/queue/default --message-body "Hello, queue!"
```

#### Viewing messages

You can also poll for messages from the command-line like so:

```
aws --endpoint-url http://localhost:9324 sqs receive-message --queue-url http://localhost:9324/queue/default --wait-time-seconds 10
```

### Creating new queues
You can create new queues by using the command-line or configuring ElasticMQ directly.

##### AWS CLI
```
aws --endpoint-url http://localhost:9324 sqs create-queue --queue-name newqueue
```

##### Edit ElasticMQ configuration file
Navigate to the directory where the configuration files reside and edit the `elasticmq.conf` file to add a new entry for each queue to the `queue` block.

```
queues {
    default {
        defaultVisibilityTimeout = 10 seconds
        delay = 5 seconds
        receiveMessageWait = 0 seconds
    },
    newqueue {
        defaultVisibilityTimeout = 10 seconds
        delay = 5 seconds
        receiveMessageWait = 0 seconds
    }
}
```

> **Note**: The configuration directory location inside the container is located at `/opt/config`. If you mounted that volume onto your host, you can also find the configuration files there.

After editing the `elasticmq.conf` file, you need to restart the ElasticMQ server by running the `supervisorctl restart elasticmq` command inside the container. If you're editing the configuration file outside of the container, use this command: 

```
docker exec -it alpine-sqs sh -c "supervisorctl restart elasticmq"
``` 

#### Registering new queues with the UI
To be able to visualize newly created queues, you need to edit the `sqs-insight.conf` file to register the new queue with the UI server. Edits to this file are automatically detected by the server and does not require a restart.

Configure a new endpoint like this:

```
"endpoints": [
        {
           "key": "notValidKey",
           "secretKey": "notValidSecret",
           "region": "eu-central-1",
           "url": "http://localhost:9324/queue/default"
        },
        {
           "key": "notValidKey",
           "secretKey": "notValidSecret",
           "region": "eu-central-1",
           "url": "http://localhost:9324/queue/newqueue"
        }
    ]

```

All the fields, except the `url` field, are required by `sqs-insight` to function but are not used when pointing it to a local queue server. This means that the values in those fields are not relevant for the UI to work correctly.

> Consult the [AWS CLI Command Reference](http://docs.aws.amazon.com/cli/latest/reference/sqs/index.html#cli-aws-sqs) or the [AWS SDK for Java](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/examples-sqs-message-queues.html) guide for more examples and information.

## License

This project is licensed under the GNU General Public License, version 3.0. See the [LICENSE](./LICENSE) file for details.
