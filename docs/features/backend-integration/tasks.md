# Tasks: Backend Integration & Optimization

## Phase 1: Backend Configuration
- [x] 1. Add CORS middleware to `backend/src/main.py` to allow Flutter app requests.
- [x] 2. Update `backend/src/api_router.py` to correctly select `GeminiClient` based on valid API Key presence, not just env name.
- [x] 3. Update `backend/src/config.py` to handle empty API keys gracefully (fallback to Mock or error).

## Phase 2: Docker & Deployment Support (Optional but good for Integration)
- [ ] 4. Create `backend/Dockerfile` for consistent execution environment.
- [ ] 5. Create `docker-compose.yml` to run Backend + (Future DB).

## Phase 3: Documentation
- [x] 6. Update `backend/README.md` with instructions on getting Gemini API Key and setting up `.env`.
- [x] 7. Add Troubleshooting section for common connectivity issues (Android `10.0.2.2` vs localhost).

## Phase 4: Integration Verification
- [x] 8. Verify FastAPI is running and accessible.
- [x] 9. (Manual) Test `POST /generate` with Swagger UI or App.
