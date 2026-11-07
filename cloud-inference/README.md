# Run ParkOps camera inference locally

This semester-project setup runs the YOLO worker on your computer. It reads
frames from three Opentopia parking cameras, runs `best.pt` locally, then
writes counts and detections to one Firestore document per camera in project
`pblparkopsfaiq`. The Flutter app listens to the selected camera's document.

No Cloud Run service, Cloud Scheduler job, model bucket, or Google Cloud
billing setup is needed. Your computer must remain on, connected to the
internet, and running the Python worker for new results to appear. The worker
processes all three cameras immediately, then starts another pass every 30
seconds.

The laptop operator starts the worker when the team asks for ML results and
stops it with **Ctrl+C** when they are done. The app reads the shared results
from Firestore, so teammates do not need the model, Python, or a connection to
the laptop's local network. Each camera result is stored in
`camera_inference/opentopia-<camera id>`. When a result is more than two
minutes old, the Camera tab marks it as stale and tells users to ask the laptop
operator to start the worker.

## 1. Put the model on your computer

Keep the weights out of Git. The default location is:

```text
cloud-inference/models/best.pt
```

Alternatively, store the file elsewhere and pass its path with `--model`.

## 2. Install local dependencies (Windows PowerShell)

Use Python 3.11-3.13. From the repository root:

```powershell
python -m venv .\cloud-inference\.venv
.\cloud-inference\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r .\cloud-inference\requirements.txt
```

This requirements file installs the CUDA 12.4 build of PyTorch and its
matching TorchVision. For an NVIDIA GPU, the included PyTorch runtime is
enough; you do not need to install the full CUDA Toolkit separately. The
Windows NVIDIA driver must support CUDA 12.4 or newer. The configured GTX
1650 and driver 555.97 were verified with this setup.

If PowerShell prevents environment activation, run the venv interpreter
directly instead:

```powershell
.\cloud-inference\.venv\Scripts\python.exe -m pip install -r .\cloud-inference\requirements.txt
```

PyTorch and Ultralytics may take a while and use several GB of disk space.
The worker selects CUDA GPU 0 by default and fails rather than silently using
the CPU if CUDA is unavailable. Use `--device cpu` only if you intentionally
want CPU inference.

## 3. Allow your local worker to write to Firestore

The worker uses Application Default Credentials (ADC); it does not use a
service-account key file. Install the Google Cloud CLI if it is not already
installed, then authenticate with the Google account that has access to the
Firebase project:

```powershell
gcloud auth application-default login
```

The account needs the **Cloud Datastore User** IAM role
(`roles/datastore.user`) on project `pblparkopsfaiq` to write the result
document. Ask the Firebase/Google Cloud project owner to grant this role if
your account does not already have it. This login does not require enabling
billing by itself.

The Flutter client's Firestore rule still allows signed-in app users to read
`camera_inference` and denies client writes. The local worker uses ADC and
Firestore IAM, so its writes are not controlled by client security rules.

## 4. Check the model's actual class labels

From the repository root, run:

```powershell
.\cloud-inference\.venv\Scripts\python.exe .\cloud-inference\run_local.py --model "D:\path\to\best.pt" --show-classes
```

The output lists the exact class labels in the weights. Use those labels for
`--vehicle-labels` and `--empty-space-labels`. The defaults are examples only;
if a label does not match exactly (ignoring case, spaces, `_`, and `-`), it
will not contribute to that count.

## 5. Run one inference, then keep it running

First try one frame/result:

```powershell
.\cloud-inference\.venv\Scripts\python.exe .\cloud-inference\run_local.py `
  --model "D:\path\to\best.pt" `
  --project pblparkopsfaiq `
  --vehicle-labels "car,vehicle,truck,bus,motorcycle" `
  --empty-space-labels "empty,empty_space" `
  --once
```

Replace the label examples with the model's actual labels. To keep the worker
available for your teammates, run the same command without `--once`. It starts
immediately, then processes all three camera feeds every 30 seconds. Press
**Ctrl+C** to stop. If the model is at the default
`cloud-inference\models\best.pt`, `--model` can be omitted. The
`--camera-url` option overrides only the 17916 feed.

The worker logs the inference device after each successful camera frame. It
should say `cuda:0` when using the first NVIDIA GPU.

Once inference succeeds, the worker logs the counts and updates that camera's
Firestore document. Open the app's Camera tab while signed in and choose a
camera to see its frame, detections, and counts. A camera that cannot provide
a frame is reported in the terminal while the worker continues to the other
cameras; model or Firestore errors are reported and stop the worker.

The configured feeds are:

| Firestore document | Camera | Frame URL |
|---|---|---|
| `opentopia-17916` | Parking with Apartment View - Osaka | `http://118.243.55.168:84/VIDEO.CGI` |
| `opentopia-17921` | Parking Lot - Tokyo | `http://119.242.68.125:84/VIDEO.CGI` |
| `opentopia-17917` | Parking - Tokyo | `http://125.193.245.91:84/VIDEO.CGI` |

`--interval` controls the seconds between complete passes over all three
cameras. `--camera-url` only overrides the 17916 feed; the other two use their
configured URLs.

## Add another camera feed

Adding a camera only to `lib/features/parking/data/camera_feeds.dart` adds it
to the app's camera selector and lets users open its Opentopia page. It does
not start inference for that feed. The app looks for a Firestore document
whose ID matches the selected feed ID, so until the worker publishes that
document the app shows that it is waiting for the laptop worker.

To enable inference for a new camera, add the same camera ID, title, and
direct JPEG/MJPEG frame URL to `CAMERA_SOURCES` in
`cloud-inference/main.py`, as well as an app entry in
`lib/features/parking/data/camera_feeds.dart`. The worker writes results to
`camera_inference/<camera id>`, so both entries must use exactly the same ID.
Confirm the direct frame URL returns a JPEG frame, then stop and restart the
worker; it reads `CAMERA_SOURCES` when it starts.

## Limits

The worker counts model detections per sampled frame. It does not yet map
detections to specific parking bays or confirm bay availability. The camera is
a public third-party feed and may be unavailable or change format. Use it only
if its terms allow automated processing.

## Tests

From the repository root:

```powershell
python -m unittest discover -s cloud-inference/tests -v
```
