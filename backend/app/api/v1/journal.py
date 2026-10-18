import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.journal import (
    JournalCreateRequest,
    JournalDetailResponse,
    JournalListResponse,
    JournalSummaryResponse,
    JournalUpdateRequest,
)
from app.services.journal_service import JournalService

router = APIRouter(prefix="/journal", tags=["Journal"])


@router.post(
    "",
    response_model=JournalDetailResponse,
    summary="Create a journal entry",
    description="Creates a private journal entry. Idempotent on client_id (returns 200 OK on replay, 201 Created on initial creation).",
)
def create_journal_entry(
    req: JournalCreateRequest,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> JournalDetailResponse:
    journal_service = JournalService(db)
    try:
        entry, created = journal_service.record_entry(
            user_id=current_user.id,
            client_id=req.client_id,
            title=req.title,
            body=req.body,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    response.status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
    return JournalDetailResponse.model_validate(entry)


@router.get(
    "",
    response_model=JournalListResponse,
    status_code=status.HTTP_200_OK,
    summary="List journal entries",
    description="Returns cursor-paginated journal entries with sanitized previews (up to 80 chars). Full body is never sent over the wire in list view.",
)
def list_journal_entries(
    limit: int = Query(default=20, ge=1, le=100, description="Items per page (1-100)"),
    cursor: Optional[str] = Query(default=None, description="Cursor for pagination"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> JournalListResponse:
    journal_service = JournalService(db)
    summaries, next_cursor, has_more = journal_service.list_entries(
        user_id=current_user.id,
        limit=limit,
        cursor=cursor,
    )

    return JournalListResponse(
        items=[JournalSummaryResponse(**item) for item in summaries],
        next_cursor=next_cursor,
        has_more=has_more,
    )


@router.get(
    "/{journal_id}",
    response_model=JournalDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get a journal entry by ID",
    description="Returns the full journal entry including complete body. Returns 404 Not Found if non-existent or owned by another user.",
)
def get_journal_entry(
    journal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> JournalDetailResponse:
    journal_service = JournalService(db)
    entry = journal_service.get_entry(user_id=current_user.id, journal_id=journal_id)
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found.",
        )
    return JournalDetailResponse.model_validate(entry)


@router.patch(
    "/{journal_id}",
    response_model=JournalDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a journal entry by ID",
    description="Updates title or body of a journal entry. Returns 404 Not Found if non-existent or owned by another user.",
)
def update_journal_entry(
    journal_id: uuid.UUID,
    req: JournalUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> JournalDetailResponse:
    journal_service = JournalService(db)
    updates = req.model_dump(exclude_unset=True)
    entry = journal_service.update_entry(
        user_id=current_user.id,
        journal_id=journal_id,
        updates=updates,
    )
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found.",
        )
    return JournalDetailResponse.model_validate(entry)


@router.delete(
    "/{journal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a journal entry by ID",
    description="Permanently deletes a journal entry. Returns 404 Not Found if non-existent or owned by another user.",
)
def delete_journal_entry(
    journal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Response:
    journal_service = JournalService(db)
    deleted = journal_service.delete_entry(user_id=current_user.id, journal_id=journal_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found.",
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
