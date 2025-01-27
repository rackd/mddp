#!/usr/bin/env python3

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field
import cv2
import numpy as np
import os
from pathlib import Path
from typing import List

app = FastAPI()

class MotionDetectionRequest(BaseModel):
    filename: str = Field(..., description="Name of the video file.")
    absolute_path: str = Field(..., alias="absolute.path", description="Absolute directory path to the video file.")
    file_lastModifiedTime: str = Field(..., alias="file.lastModifiedTime", description="Last modified time of the video file.")
    frame_count: int = Field(..., description="Number of frames extracted.")
    class Config:
        populate_by_name = True

class MotionDetectionResponse(BaseModel):
    filename: str = Field(..., description="Name of the video file.")
    absolute_path: str = Field(..., alias="absolute.path", description="Absolute directory path to the video file.")
    file_lastModifiedTime: str = Field(..., alias="file.lastModifiedTime", description="Last modified time of the video file.")
    frame_count: int = Field(..., description="Number of frames extracted.")
    motion_detected: int = Field(..., description="Indicates if motion was detected (1 for yes, 0 for no).")
    motions: List[List[int]] = Field(..., description="List of motion segments with start and end frame indices.")
    class Config:
        populate_by_name = True

def detect_motion_segments(frames: List[np.ndarray], threshold: int = 5000, diff_threshold: int = 25) -> (int, List[List[int]]):
    motion_detected = 0
    motions = []
    motion_start = None

    for i in range(1, len(frames)):
        frame1 = frames[i - 1]
        frame2 = frames[i]

        # Compute absolute difference between frames
        diff = cv2.absdiff(frame1, frame2)
        # Apply threshold to get binary image
        _, thresh = cv2.threshold(diff, diff_threshold, 255, cv2.THRESH_BINARY)
        # Count non-zero pixels (motion pixels)
        motion_pixels = np.sum(thresh) / 255

        if motion_pixels > threshold:
            if motion_start is None:
                motion_start = i - 1  # Start from previous frame
        else:
            if motion_start is not None:
                motion_end = i - 1
                motions.append([motion_start, motion_end])
                motion_detected = 1
                motion_start = None

    # Handle case where motion continues till the last frame
    if motion_start is not None:
        motion_end = len(frames) - 1
        motions.append([motion_start, motion_end])
        motion_detected = 1

    return motion_detected, motions

def read_frames(input_video_path: Path, frame_count: int) -> List[np.ndarray]:
    frames = []
    fixed_output_dir = Path("/frames").resolve()
    base_filename = input_video_path.stem

    for i in range(1, frame_count + 1):
        frame_filename = f"{base_filename}_{i}.png"
        frame_path = fixed_output_dir / frame_filename
        frame = cv2.imread(str(frame_path), cv2.IMREAD_GRAYSCALE)
        if frame is None:
            raise FileNotFoundError(f"Frame not found or unreadable: {frame_path}")
        frames.append(frame)

    return frames

@app.post("/detect_motion", response_model=MotionDetectionResponse)
def detect_motion(request: MotionDetectionRequest):
    try:
        # Construct the input video path by combining absolute_path and filename
        input_video_path = (Path(request.absolute_path).resolve() / request.filename).resolve()
        # Define the fixed output directory
        fixed_output_dir = Path("/frames").resolve()

        # Read frames from the fixed output directory
        frames = read_frames(input_video_path, request.frame_count)

        # Detect motion segments
        motion_detected, motions = detect_motion_segments(frames)

        # Construct the response
        response = MotionDetectionResponse(
            filename=request.filename,
            absolute_path=request.absolute_path,
            file_lastModifiedTime=request.file_lastModifiedTime,
            frame_count=request.frame_count,
            motion_detected=motion_detected,
            motions=motions
        )

        return response

    except Exception:
        raise HTTPException(status_code=500, detail="Motion detection failed.")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return Response(status_code=500, content='')

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "__main__:app",
        host="0.0.0.0",
        port=8778,
        reload=True
    )
