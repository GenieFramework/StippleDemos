FROM julia:latest

# setting the app's name (mandatory, change as needed)
ENV APP="GenieTemplate"

#  ----------------------  app settings -------------------------------

# use "prod" for final deployment and "dev", "qa", "test" during testing/development
ENV GENIE_ENV="dev"
ENV JULIA_REVISE="on"

# set up app environment
ENV PORT="8000"
EXPOSE ${PORT}

# WSPORT is identical to PORT unless you want to run the WebSocket server on a different port
# ENV WSPORT="8001"
# EXPOSE ${WSPORT}

# optional BASEPATH, default is ""
# ENV BASEPATH="/genietemplate"

# some hoster require a separate basepath for ws connections
# WSBASEPATH="/ws"

# ----------------------- custom dependencies ---------------------------

# install other dependencies here, e.g. for image processing or databases
# RUN apt-get update && apt-get install -y <your-packages>

# ----------------------------  setup  ----------------------------------

# create dedicated user
RUN useradd --create-home --shell /bin/bash genie

# setting up the app's directory
RUN mkdir /home/genie/${APP} && chown genie:genie /home/genie/${APP}
WORKDIR /home/genie/${APP}

ENV JULIA_DEPOT_PATH="/home/genie/.julia"
ENV GENIE_HOST="0.0.0.0"

# if you use PythonCall or other Python packages
ENV PYTHONUNBUFFERED="1"

# instantiate Julia packages with only config files copied for better caching
USER genie

COPY --chown=genie:genie *.toml precompile.jl /home/genie/${APP}/
RUN mkdir src && echo "module ${APP} end" > src/${APP}.jl

# instantiate packages and precompile
RUN julia --project precompile.jl

# copy the full app and precompile
COPY --chown=genie:genie . /home/genie/${APP}
RUN julia --project -e 'using Pkg; Pkg.precompile();'

# set CondaPkg mode to offline to avoid rebuilds of Conda
ENV JULIA_CONDAPKG_OFFLINE="true"

# set an environment variable to indicate that we are running inside Docker
ENV DOCKER="true"

# run app
ENTRYPOINT ["julia", "--project", "--threads=auto", "app.jl", "serve"]