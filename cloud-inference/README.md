# ParkOps camera inference worker

This Cloud Run service handles one Opentopia camera for the MVP. Cloud Scheduler
calls `/infer` once per minute. The worker reads one JPEG frame from the
camera's MJPEG endpoint, runs `best.pt`, and writes the counts and detections to
`camera_inference/opentopia-17916` in Firestore.

The model stays in a private Cloud Storage bucket. Do not commit `best.pt`,
service-account keys, or signed URLs to this repository.

## Configure and deploy

Use the Google Cloud project already associated with the app
(`pblparkopsfaiq`), after confirming billing is enabled. Create a private
regional bucket and upload the weights, for example:

```powershell
gcloud config set project pblparkopsfaiq
gcloud storage buckets create gs://pblparkopsfaiq-parkops-models --location=asia-southeast1 --uniform-bucket-level-access
gcloud storage cp .\best.pt gs://pblparkopsfaiq-parkops-models/best.pt
```

Enable Cloud Run, Cloud Build, Artifact Registry, Cloud Scheduler, Firestore,
and Cloud Storage APIs. Create a Cloud Run service account with
`roles/storage.objectViewer` on the model bucket and `roles/datastore.user` on
the project. Build and deploy the service with that service account and these
environment variables:

- `MODEL_GCS_URI=gs://pblparkopsfaiq-parkops-models/best.pt`
- `CAMERA_URL=http://118.243.55.168:84/VIDEO.CGI`
- `VEHICLE_CLASS_NAMES=car,vehicle,truck,bus,motorcycle`
- `EMPTY_SPACE_CLASS_NAMES=empty,empty_space,empty slot,empty parking space,empty bay,free space,vacant`
- `CONFIDENCE_THRESHOLD=0.25`

Set Cloud Run request concurrency to `1` for the first deployment. Keep the
service private. Create a Cloud Scheduler HTTP job with schedule `* * * * *`,
targeting the service's `/infer` URL with method `POST` and OIDC authentication
from a service account granted `roles/run.invoker` on the service.

The first successful inference creates the Firestore document consumed by the
Flutter app. The worker uses the model's class labels; update the two class-name
environment variables if the labels in `best.pt` use different names.

Run the local class-counting tests from the repository root with:

```powershell
python -m unittest discover -s cloud-inference/tests -v
```

## App read access

The app's authenticated users need read access to `camera_inference` documents,
but clients must not write inference results. If managing Firestore rules,
allow reads for authenticated users and deny client writes for this collection;
the Cloud Run service writes with its service account through the Admin SDK.

## Limits

This first version publishes vehicle and empty-space detection counts. It does
not map detections to individual parking bays. The camera is a public third-party
feed and can go offline or change format; confirm its processing terms and
availability before relying on it. A Cloud Scheduler run can fail if the
camera endpoint is unreachable from Cloud Run.
