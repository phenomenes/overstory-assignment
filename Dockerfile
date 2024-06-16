# syntax=docker/dockerfile:1
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && apt-get install -y \
	build-essential \
	libgdal-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --upgrade pip \
    && pip install -r requirements.txt \
    && groupadd -r appuser && useradd -r -g appuser appuser

COPY . .

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8888

CMD ["gunicorn", "--bind", ":8888", "--workers", "3", "app:app"]
