#!/bin/bash
limactl stop gemini && limactl remove gemini && ssh-keygen -R "[localhost]:8222"