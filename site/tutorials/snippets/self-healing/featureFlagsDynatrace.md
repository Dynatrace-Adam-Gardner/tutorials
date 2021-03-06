## Self-healing with feature flags
Duration: 2:00

Next, you will learn how to use the capabilities of Keptn to provide self-healing for an application with feature flags based on the [Unleash feature toggle framework](https://unleash.github.io/). 


Positive
: For the sake of this tutorial, we will onboard Unleash as a Keptn project. The carts microservice is already pre-configured for this.

To quickly get an Unleash server up and running with Keptn, follow these instructions:

1. Make sure you are in the correct folder of your examples directory:

    ```
    cd examples/unleash-server
    ```


1. Create a new project using the `keptn create project` command:

    ```
    keptn create project unleash --shipyard=./shipyard.yaml
    ```

1. Onboard unleash and unleash-db using the `keptn onboard service` command:

    ```
    keptn onboard service unleash-db --project=unleash --chart=./unleash-db
    keptn onboard service unleash --project=unleash --chart=./unleash
    ```

1. Send new artifacts for unleash and unleash-db using the `keptn send new-artifact` command:

    ```
    keptn send event new-artifact --project=unleash --service=unleash-db --image=postgres:10.4
    keptn send event new-artifact --project=unleash --service=unleash --image=docker.io/keptnexamples/unleash:1.0.0
    ```

1. Get the URL (`unleash.unleash-dev.KEPTN_DOMAIN`):

    ```
    echo http://unleash.unleash-dev.$(kubectl get cm keptn-domain -n keptn -o=jsonpath='{.data.app_domain}')
    ```

1. Open the URL in your browser and log in using the following credentials:
   * Username: keptn
   * Password: keptn

You should be able to login using the credentials *keptn/keptn*.

## Configure the Unleash server
Duration: 4:00

In this tutorial, we are going to introduce feature toggles for two scenarios:

1. Feature flag for a very simple caching mechanism that can speed up the delivery of the website since it skips the calls to the database but instead replies with static content.

1. Feature flag for a promotional campaign that can be enabled whenever you want to run a promotional campaign on top of your shopping cart.

To set up both feature flags, navigate to your Unleash server and log in. 

1. Click on the red **+** to add a new feature toggle.
  ![unleash-add](./assets/unleash-add.png)

1. Name the feature toggle **EnableItemCache** and add **carts** in the description field.
  ![unleash-cache](./assets/unleash-cache.png)

1. Create another feature toggle by following the same procedure and by naming it the feature toggle **EnablePromotion** and by adding **carts** in the description field.
  ![unleash-promotion](./assets/unleash-promotion.png)


## Configure Keptn
Duration: 5:00

Now, everything is set up in the Unleash server. For Keptn to be able to connect to the Unleash server, we have to add a secret with the Unleash API URL as well as the Unleash tokens.

1. In order for Keptn to be able to use the Unleash API, we need to add the credentials as a secret to our Keptn namespace. In this tutorial, we do not have to change the values for UNLEASH_SERVER, UNLEASH_USER, and UNLEASH_TOKEN, but in your own custom scenario this might be needed to change it to your actual Unleash URL, user and token. 
As said, in this tutorial we can use the following command as it is:

    ```
    kubectl -n keptn create secret generic unleash --from-literal="UNLEASH_SERVER_URL=http://unleash.unleash-dev/api" --from-literal="UNLEASH_USER=keptn" --from-literal="UNLEASH_TOKEN=keptn"
    ```

1. Keptn has to be aware of the new secret to connect to the Unleash server and to set the feature toggles. Therefore, the *remediation-service* must be restarted:

    ```
    kubectl delete pod -l=run=remediation-service -n keptn
    ```

1. Finally, switch to the carts example (`cd examples/onboarding-carts`) and add the following remediation instructions

        remediations:
        - name: "Response time degradation"
          actions:
          - action: featuretoggle
            value: EnableItemCache:on
        - name: "Failure rate increase"
          actions:
          - action: featuretoggle
            value: EnablePromotion:off

    using the command:

    ```
    keptn add-resource --project=sockshop --service=carts --stage=production --resource=remediation_feature_toggle.yaml --resourceUri=remediation.yaml
    ```

    **Note:** The file describes remediation actions (e.g., `featuretoggle`) in response to problems/alerts (e.g., `Response time degradation`) that are sent to Keptn.

Now that everything is set up, next we are going to hit the application with some load and toggle the feature flags.

## Run the experiment
Duration: 5:00

To simulate user traffic, we are going to execute the following script that will constantly add items to the shopping cart.

1. Change into the folder with the load generation program within the examples repo:

    ```
    cd load-generation/bin
    ```

1. Start the according load generation program depending on your operating system (replace *_OS_ with either *linux, mac* or *win*):

    ```
    ./loadgenerator-_OS_ "http://carts.sockshop-production.$(kubectl get cm keptn-domain -n keptn -o=jsonpath='{.data.app_domain}')" 
    ```

1. Now, go back to your Unleash server in your browser. In this tutorial, we are going to turn on the promotional campaign, which purpose is to add promotional gifts to about 30&nbsp;% of the user interactions that put items in their shopping cart. 

1. Click on the toggle next to **EnablePromotion** to enable this feature flag.

    ![enable-toggle](./assets/unleash-promotion-toggle-on.png)

1. By enabling this feature flag, a not implemented function is called resulting in a *NotImplementedFunction* error in the source code and a failed response. After a couple of minutes, the monitoring tool will detect an increase in the failure rate and will send out a problem notification to Keptn.

1. Keptn will receive the problem notification/alert and look for a remediation action that matches this problem. Since we have added the `remediation.yaml` before, Keptn will find a remediation action and will trigger the corresponding action that will disable the feature flag.

1. Finally, take a look into the Keptn's Bridge to see that an open problem has been resolved:
    
    ![bridge unleash](./assets/bridge_remediation_unleash.png)

