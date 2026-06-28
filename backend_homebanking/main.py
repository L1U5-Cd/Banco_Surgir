from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.cfg_config import settings
from app.routes import route_auth, route_creditos, route_cuentas, route_operaciones

app = FastAPI(
    title="Banca Internet Banco Andino — Homebanking API",
    description="Portal del cliente de Banca Internet Banco Andino.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://homebanking-swart.vercel.app",
        "http://localhost:5173",
        "http://localhost:5174",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(route_auth.router)
app.include_router(route_cuentas.router)
app.include_router(route_operaciones.router)
app.include_router(route_creditos.router)


@app.get("/", tags=["root"])
def raiz():
    return {
        "servicio": "Banca Internet Banco Andino — Homebanking API",
        "version": "1.0.0",
        "estado": "ok",
    }


@app.get("/health")
def health():
    return {"status": "ok"}