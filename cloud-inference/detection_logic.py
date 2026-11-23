def summarize_detections(detections: list[dict]) -> dict[str, int]:
    vehicle_count = 0
    empty_space_count = 0
    for detection in detections:
        class_name = detection["className"]
        if class_name == "busy":
            vehicle_count += 1
        elif class_name == "empty":
            empty_space_count += 1

    return {
        "vehicleCount": vehicle_count,
        "emptySpaceCount": empty_space_count,
    }
