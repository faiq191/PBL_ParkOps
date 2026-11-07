def normalize_class_name(name: str) -> str:
    return " ".join(name.strip().lower().replace("_", " ").replace("-", " ").split())


def summarize_detections(
    detections: list[dict],
    *,
    vehicle_labels: set[str],
    empty_space_labels: set[str],
) -> dict[str, int]:
    vehicle_names = {normalize_class_name(name) for name in vehicle_labels}
    empty_space_names = {
        normalize_class_name(name) for name in empty_space_labels
    }

    vehicle_count = 0
    empty_space_count = 0
    for detection in detections:
        class_name = normalize_class_name(detection["className"])
        vehicle_count += class_name in vehicle_names
        empty_space_count += class_name in empty_space_names

    return {
        "vehicleCount": vehicle_count,
        "emptySpaceCount": empty_space_count,
    }
