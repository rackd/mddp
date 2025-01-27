#!/usr/bin/env python3

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field
import ffmpeg
import re
import sys
from pathlib import Path
from typing import Optional, List

app = FastAPI()

class FrameExtractionRequest(BaseModel):
    filename: str = Field(..., description="Name of the video file.")
    absolute_path: str = Field(..., alias="absolute.path", description="Absolute directory path to the video file.")
    file_lastModifiedTime: str = Field(..., alias="file.lastModifiedTime", description="Last modified time of the video file.")
    class Config:
        populate_by_name = True

class FrameExtractionResponse(BaseModel):
    filename: str = Field(..., description="Name of the video file.")
    absolute_path: str = Field(..., alias="absolute.path", description="Absolute directory path to the video file.")
    file_lastModifiedTime: str = Field(..., alias="file.lastModifiedTime", description="Last modified time of the video file.")
    frame_count: int = Field(..., description="Number of frames extracted.")
    class Config:
        populate_by_name = True

def extract_frames_and_count(input_video_path: Path, output_dir: Path, fps: int = 1) -> int:
    try:
        if not input_video_path.is_file():
            return 0

        output_dir.mkdir(parents=True, exist_ok=True)
        base_filename = input_video_path.stem
        output_pattern = output_dir / f"{base_filename}_%d.png"
        frame_regex = re.compile(r'^frame=(\d+)')
        process = (
            ffmpeg
            .input(str(input_video_path))
            .filter('fps', fps=fps)
            .output(str(output_pattern))
            .global_args('-progress', 'pipe:1', '-nostats', '-v', 'quiet')
            .run_async(pipe_stdout=True, pipe_stderr=True)
        )

        frame_count = 0

        # Read progress information from stdout
        while True:
            line = process.stdout.readline()
            if not line:
                break
            line = line.decode('utf-8').strip()
            match = frame_regex.match(line)
            if match:
                frame_count = int(match.group(1))

        process.wait()
        if process.returncode != 0:
            return 0

        return frame_count

    except Exception as e:
        return 0

@app.post("/extract_frames", response_model=FrameExtractionResponse)
def extract_frames(request: FrameExtractionRequest):
    input_video_path = (Path(request.absolute_path).resolve() / request.filename).resolve()
    fixed_output_dir = Path("/frames").resolve()
    fps = 1

    frame_count = extract_frames_and_count(input_video_path, fixed_output_dir, fps)

    if frame_count == 0:
        raise HTTPException(status_code=500, detail="Frame extraction failed.")

    response = FrameExtractionResponse(
        filename=request.filename,
        absolute_path=request.absolute_path,
        file_lastModifiedTime=request.file_lastModifiedTime,
        frame_count=frame_count
    )
    return response

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return Response(status_code=500, content='')

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "__main__:app", 
        host="0.0.0.0",
        port=8779,
        reload=True
    )
