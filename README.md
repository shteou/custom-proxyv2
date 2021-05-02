# custom-proxyv2

## Description

custom-proxyv2 is a version of the `istio/proxyv2` image which handles `SIGTERM` in a more graceful manner.

When performing a Kubernetes rollout deployment, istio is terminated immediately which severs all connections
to containers which are routed through istio and leaves containers unable to make downstream requests. This 
causes a number of 503s when the deployment shoud othherwise be zero downtime. This isn't typically an issue
if you are performing canary deploys with istio.

This is accomplished by overriding the entrypoint of proxyv2 with a script to trap `SIGTERM` and wait for
all listening connections to be terminated before passing the signal on to the sidecar's `pilot-agent` process.

## Limitations

The graceful shutdown script assumes that all other containers will close any listening TCP ports. It also 
assumes that no other containers will attempt to make external calls after these listening ports have been closed.

## Prior art

This was based on a similar approach, mentioned on [this GitHub issue](https://github.com/istio/istio/issues/7136) and
[this one](https://github.com/istio/istio/issues/12183). It's also documented in WeaveWorks' [Flagger docs](https://docs.flagger.app/tutorials/zero-downtime-deployments).

This approach differs in that we simply customise the entrypoint of the image, rather than adding a pre-stop handler.  
Both approaches require a custom proxyv2 image.

I was also unable to get the above approach to work correctly, having to override the numeric comparison with a string
comparison, and filter out listening connections from `pilot-agent` as well as `envoy`. It's not clear to me why
this is the case, however I noted that these approaches still solve the issue of 503s, but have the unintended side-effect
of delaying shutdown until the `terminationGracePeriod` has passed.

## How to use the custom image

Assuming you are using automatic sidecar injection on Kubernetes, the custom image can be added
with the folowing steps:

1. Edit the istio-sidecar-config configmap
1. Update the `global.proxy.image` and `global.tag` values to reference the customised image
1. Depending on your istio version, restart any `istio-sidecar-injector` pods, or `istiod` pods

## Building the image

You can build the image for a specific istio version with `docker build -t my-custom-image:version --build-arg ISTIO_VERSION=1.9.4 .`.  
You'll need to push this to an accessible image registry.

### Pre-built OCI images

Pre-built images are available as `shteou/custom-proxyv2`.  
The images are tagged with a tuple of the custom version and target istio version. e.g. `shteou/custom-proxyv2:1.0.0-1.9.4`.

