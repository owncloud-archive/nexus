# History

A glimpse of past efforts to evolve the architecture in reverse chronological order. The current architecture is shown in README.md

## reva
After clarification we recognized that the only true difference between reva and the async rest+json protocol in a storage broker and provider architecture was the grpc+protobuf based protocol.

![reva](/img/storage%20history%20and%20future%20-%207%20-%20reva.jpg?raw=true "reva")

The storage providers do exist as seperate implementations in reva, but they can be moved to separate services. The broker is the other part of reva. The ocproxy can live ... however I (jfd) no longer see it in the future branch of reva ... no idea where it is gone :shrug:


## Asynchronous protocol

The asynchronous protocol is intended to be used by all clients: web, desktop and mobile. But for the time being the existing webdav apis will be used.

![async](/img/storage%20history%20and%20future%20-%206%20-%20async.jpg?raw=true "async")

When the storage has been split up into dedicated components or services and the async protocol works between those componets we could extend the usage to other clients. Some things were unclear when discussing this with CERN, so we compared it to the current reva architecture.


## Storage broker and provider

After the first storage workshop ownCloud proposed to split the storage component into a manager or broker and multiple storage providers.

![broker and provider](/img/storage%20history%20and%20future%20-%205%20-%20broker%20and%20provider.jpg?raw=true "broker and provider")

The providers can implement several capabilities like versioning, trashbin and sharing. The idea being that clients should talk directy to storage providers in the future. For that we also described an asynchronous protocol.


## cernbox

CERN replaced the underlying storage functionality with a eos based solution.

![cernbox](/img/storage%20history%20and%20future%20-%204%20-%20cernbox.jpg?raw=true "cernbox")


## Phoenix

With Phoenix we tested a new layer for the web frontend. Basically, a new layer on top of the existing APIs.

![phoenix](/img/storage%20history%20and%20future%20-%203%20-%20phoenix.jpg?raw=true "phoenix")


## Cut at routing

For Switch jfd tried to cut core at the routing. In the front there was a gateway thet autherizes requests and forwards them to a backend service, based on the username. In the back, multiple versions of the app framework (including the storage) would only authorize requests using a jwt and then immediately do the routing.

![cut at routing](/img/storage%20history%20and%20future%20-%202%20-%20cut%20at%20routing.jpg?raw=true "cut at routing") 

Unfortunately, the approach was not followed up when performance improvements made this kind of load distribution unnecessary.

## Current core

Currently, ownCloud core consists of multiple components that are not clearly separated:

![current core](/img/storage%20history%20and%20future%20-%201%20-%20core.jpg?raw=true "Current core")
