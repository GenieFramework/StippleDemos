FROM julia:latest

# user
RUN useradd --create-home --shell /bin/bash genie

# app
RUN mkdir /home/genie/IrisClustering
COPY . /home/genie/IrisClustering
WORKDIR /home/genie/IrisClustering

RUN chown genie:genie -R *

USER genie

RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile(); '

ENV JULIA_DEPOT_PATH "/home/genie/.julia"
ENV GENIE_ENV "dev"
ENV HOST "0.0.0.0"
ENV EARLYBIND "true"

CMD julia -e 'using Pkg; Pkg.activate("."); include("IrisClustering_StipplePlotly.jl"); '
