// 一、查詢課程與教練的對應關係
// 資料來源：data.js 的 courses、coaches、coachCourses

// 輸入課程 ID，回傳這門課的授課教練姓名
function getCoachNames(courseid) {
    return coachCourses
        .filter(item => item.courseid === courseid)
        .map(item =>
            coaches.find(coach => coach.coachid === item.coachid)?.name
        )
        .filter(Boolean)
        .join("、");
}

// 輸入教練 ID，回傳這位教練教授的課程名稱
function getCourseNames(coachid) {
    return coachCourses
        .filter(item => item.coachid === coachid)
        .map(item =>
            courses.find(course => course.courseid === item.courseid)?.coursename
        )
        .filter(Boolean)
        .join("、");
}


// 二、表格共用工具

// 在指定的 <tr> 裡新增一格 <td>
// 如果資料是 null 或 undefined，顯示「未填寫」
function addCell(row, value) {
    const cell = row.insertCell();
    cell.textContent = value ?? "未填寫";
    return cell;
}


// 三、顯示課程列表
// 對應頁面：course.html
// 對應位置：<tbody id="courseTableBody">

// 課程的授課教練：先顯示兩位
function renderCourseCoachCell(cell, courseid) {
    const coachIds = new Set(
        coachCourses
            .filter(item => item.courseid === courseid)
            .map(item => item.coachid)
    );

    const assignedCoaches = coaches.filter(coach =>
        coachIds.has(coach.coachid)
    );

    if (assignedCoaches.length === 0) {
        cell.textContent = "尚未指派";
        return;
    }

    const container = document.createElement("div");
    container.className =
        "d-flex flex-wrap align-items-center gap-1";
    container.style.maxWidth = "260px";

    function createTag(coach) {
        const tag = document.createElement("span");
        tag.className =
            "badge bg-light text-dark border text-wrap text-start";
        tag.textContent = coach.name;
        return tag;
    }

    assignedCoaches.slice(0, 2).forEach(coach => {
        container.append(createTag(coach));
    });

    if (assignedCoaches.length > 2) {
        const extra = document.createElement("span");
        extra.className =
            "d-flex flex-wrap align-items-center gap-1 d-none";

        assignedCoaches.slice(2).forEach(coach => {
            extra.append(createTag(coach));
        });

        const toggle = document.createElement("button");
        toggle.type = "button";
        toggle.className = "btn btn-link btn-sm p-0";
        toggle.textContent = `另有 ${assignedCoaches.length - 2} 位`;
        toggle.setAttribute("aria-expanded", "false");

        toggle.addEventListener("click", () => {
            const expanded =
                toggle.getAttribute("aria-expanded") === "true";

            extra.classList.toggle("d-none", expanded);
            toggle.setAttribute("aria-expanded", String(!expanded));
            toggle.textContent = expanded
                ? `另有 ${assignedCoaches.length - 2} 位`
                : "收合";
        });

        container.append(extra, toggle);
    }

    cell.append(container);
}

function renderCourses() {
    const tbody = document.querySelector("#courseTableBody");

    // 在 coach.html 找不到這個 tbody，因此直接結束
    if (!tbody) return;

    // 每次重新顯示前先清空，避免資料列重複
    tbody.replaceChildren();

    // 取得搜尋欄內容，統一轉成小寫
    const keyword = (
        document.querySelector("#courseSearch")?.value ?? ""
    ).trim().toLowerCase();

    // 找出符合關鍵字的課程
    const filteredCourses = courses.filter(course => {
        const searchText = [
            course.courseid,
            course.coursename,
            course.coursetype,
            course.description,
            course.durationmin,
            course.price,
            getCoachNames(course.courseid),
            course.status === "active" ? "上架" : "下架"
        ].join(" ").toLowerCase();

        return searchText.includes(keyword);
    });

    if (filteredCourses.length === 0) {
        const cell = tbody.insertRow().insertCell();
        cell.colSpan = 9;
        cell.textContent = keyword
            ? "找不到符合的課程。"
            : "目前沒有課程。";
        return;
    }

    filteredCourses.forEach(course => {
        // 這裡以下原本顯示課程欄位、狀態、編輯按鈕的程式保留
        // 每門課建立一列 <tr>
        const row = tbody.insertRow();

        // 修改表格欄位時，這裡的順序要和 HTML 的 <th> 一致
        addCell(row, course.courseid);
        addCell(row, course.coursename);
        addCell(row, course.coursetype);
        addCell(row, course.description);
        addCell(row, `${course.durationmin} 分鐘`);
        addCell(row, `NT$ ${course.price}`);
        const coachCell = row.insertCell();
        renderCourseCoachCell(coachCell, course.courseid);

        // 狀態欄：停用是紅色，上架是綠色
        const statusCell = row.insertCell();
        const badge = document.createElement("span");
        badge.className = course.status === "active"
            ? "badge text-bg-success"
            : "badge text-bg-danger";

        badge.textContent = course.status === "active" ? "上架" : "下架";
        statusCell.append(badge);

        // 操作欄：每門課都有自己的編輯按鈕
        const actionCell = row.insertCell();
        const editButton = document.createElement("button");
        editButton.type = "button";
        editButton.className = "btn btn-sm btn-outline-secondary text-nowrap";
        editButton.textContent = "編輯";

        // 點擊時，把「這一筆 course」交給編輯表單
        editButton.addEventListener("click", () => openCourseForm(course));
        actionCell.append(editButton);
    });
}


// 四、顯示教練列表
// 對應頁面：coach.html
// 對應位置：<tbody id="coachTableBody">

// 教練可授課程：先顯示兩門，其餘可展開
function renderCoachCourseCell(cell, coachid) {
    const courseIds = new Set(
        coachCourses
            .filter(item => item.coachid === coachid)
            .map(item => item.courseid)
    );

    const assignedCourses = courses.filter(course =>
        courseIds.has(course.courseid)
    );

    if (assignedCourses.length === 0) {
        cell.textContent = "尚未指派";
        return;
    }

    const container = document.createElement("div");
    container.className = "d-flex flex-wrap align-items-center gap-1";
    container.style.maxWidth = "260px";

    function createTag(course) {
        const tag = document.createElement("span");
        tag.className =
            "badge bg-light text-dark border text-wrap text-start";
        tag.textContent = course.coursename;
        return tag;
    }

    // 預設顯示前兩門
    assignedCourses.slice(0, 2).forEach(course => {
        container.append(createTag(course));
    });

    if (assignedCourses.length > 2) {
        const extra = document.createElement("span");
        extra.className =
            "d-flex flex-wrap align-items-center gap-1";
        extra.classList.add("d-none");

        assignedCourses.slice(2).forEach(course => {
            extra.append(createTag(course));
        });

        const toggle = document.createElement("button");
        toggle.type = "button";
        toggle.className = "btn btn-link btn-sm p-0";
        toggle.textContent = `另有 ${assignedCourses.length - 2} 門`;
        toggle.setAttribute("aria-expanded", "false");

        toggle.addEventListener("click", () => {
            const expanded =
                toggle.getAttribute("aria-expanded") === "true";

            extra.classList.toggle("d-none", expanded);
            toggle.setAttribute("aria-expanded", String(!expanded));
            toggle.textContent = expanded
                ? `另有 ${assignedCourses.length - 2} 門`
                : "收合";
        });

        container.append(extra, toggle);
    }

    cell.append(container);
}

function renderCoaches() {
    const tbody = document.querySelector("#coachTableBody");

    // 在 course.html 找不到這個 tbody，因此直接結束
    if (!tbody) return;

    tbody.replaceChildren();

    // 取得搜尋欄內容
    const keyword = (
        document.querySelector("#coachSearch")?.value ?? ""
    ).trim().toLowerCase();

    // 找出符合關鍵字的教練
    const filteredCoaches = coaches.filter(coach => {
        const searchText = [
            coach.coachid,
            coach.coachno,
            coach.name,
            coach.gender,
            coach.phone,
            coach.email,
            getCourseNames(coach.coachid),
            coach.status === "active" ? "在職" : "離職"
        ].join(" ").toLowerCase();

        return searchText.includes(keyword);
    });

    // 沒有符合資料時，顯示提示
    if (filteredCoaches.length === 0) {
        const cell = tbody.insertRow().insertCell();
        cell.colSpan = 9;
        cell.textContent = keyword
            ? "找不到符合的教練。"
            : "目前沒有教練。";
        return;
    }

    // 顯示搜尋後的教練
    filteredCoaches.forEach(coach => {
        const row = tbody.insertRow();

        // 修改教練表格欄位時，也要同步修改 coach.html 的 <th>
        addCell(row, coach.coachid);
        addCell(row, coach.coachno);
        addCell(row, coach.name);
        addCell(row, coach.gender);
        addCell(row, coach.phone);
        addCell(row, coach.email);
        // 可授課程欄
        const courseCell = row.insertCell();
        renderCoachCourseCell(courseCell, coach.coachid);

        // 狀態欄：在職綠色、離職紅色
        const statusCell = row.insertCell();
        const badge = document.createElement("span");

        badge.className = coach.status === "active"
            ? "badge text-bg-success"
            : "badge text-bg-danger";

        badge.textContent = coach.status === "active" ? "在職" : "離職";
        statusCell.append(badge);

        // 最後一欄：這位教練的編輯按鈕
        const actionCell = row.insertCell();
        const editButton = document.createElement("button");
        editButton.type = "button";
        editButton.className = "btn btn-sm btn-outline-secondary text-nowrap";
        editButton.textContent = "編輯";
        editButton.addEventListener("click", () => openCoachForm(coach));
        actionCell.append(editButton);
    });
}


// 五、課程表單：新增和編輯共用同一個 Bootstrap Modal

// null：目前是新增課程
// 數字：目前正在編輯這個 courseid 的課程
let editingCourseId = null;

// 勾選清單：每欄最多五個，再往右排列
function layoutCheckboxOptions(container, count) {
    container.style.display = "grid";
    container.style.gridTemplateRows =
        `repeat(${Math.min(Math.max(count, 1), 5)}, auto)`;
    container.style.gridAutoFlow = "column";
    container.style.gridAutoColumns = "minmax(160px, 1fr)";
    container.style.gap = "6px 16px";
    container.style.overflowX = "auto";
    container.style.paddingBottom = "6px";
}

// 顯示所有教練的核取方塊，讓管理員選擇授課教練
function renderCoachOptions(selectedCourseId = null) {
    const container = document.querySelector("#courseCoachOptions");
    container.replaceChildren();
    layoutCheckboxOptions(container, coaches.length);

    coaches.forEach(coach => {
        const wrapper = document.createElement("div");
        wrapper.className = "form-check";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "form-check-input";
        checkbox.name = "coachIds";
        checkbox.value = coach.coachid;
        checkbox.id = `coachOption${coach.coachid}`;

        // 編輯課程時，勾選原本的授課教練
        checkbox.checked = coachCourses.some(item =>
            item.courseid === selectedCourseId &&
            item.coachid === coach.coachid
        );

        const label = document.createElement("label");
        label.className = "form-check-label";
        label.htmlFor = checkbox.id;
        label.textContent = coach.name;

        wrapper.append(checkbox, label);
        container.append(wrapper);
    });
}

// 開啟課程表單
// 沒有傳入 course → 新增；有傳入 course → 編輯
function openCourseForm(course = null) {
    const form = document.querySelector("#courseForm");
    form.reset();

    editingCourseId = course?.courseid ?? null;

    document.querySelector("#courseModalTitle").textContent =
        course ? "編輯課程" : "新增課程";

    // 新增課程預設上架；編輯時才顯示「停用課程」選項
    document.querySelector("#courseStatusGroup").hidden = !course;
    document.querySelector("#courseStatus").value = course?.status ?? "active";

    // 編輯時帶入原本資料；新增時欄位留空
    document.querySelector("#courseName").value = course?.coursename ?? "";
    document.querySelector("#courseType").value =
        course?.coursetype ?? "重量訓練";
    document.querySelector("#courseDescription").value =
        course?.description ?? "";
    document.querySelector("#coursePrice").value = course?.price ?? "";

    renderCoachOptions(editingCourseId);

    // 顯示 Bootstrap Modal
    bootstrap.Modal.getOrCreateInstance(
        document.querySelector("#courseModal")
    ).show();
}



// 六、處理「新增課程」按鈕和表單儲存
// 只有 course.html 有 addCourseBtn，所以教練頁會跳過這段


// 六、課程新增、編輯、狀態與授課教練儲存

// 發送 API 請求
async function courseApiRequest(url, method, body) {
    const response = await fetch(url, {
        method,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(method, url, response.status, errorText);

        const messages = {
            400: "資料格式不正確，請確認課程欄位。",
            401: "請先登入管理員帳號。",
            403: "沒有操作權限，請確認登入狀態。",
            404: "找不到課程或教練，請重新整理資料。",
            409: "資料發生衝突，請確認內容。"
        };

        throw new Error(
            messages[response.status]
            || `儲存失敗，狀態碼：${response.status}`
        );
    }

    // 同時支援 JSON 回應與空白回應
    const text = await response.text();
    return text ? JSON.parse(text) : null;
}

// 從課程頁更新授課教練
async function saveCourseCoaches(courseid, selectedCoachIds) {
    const selectedIds = new Set(selectedCoachIds);

    // 只處理原本有授課，或這次被選取的教練
    const affectedCoaches = coaches.filter(coach =>
        selectedIds.has(coach.coachid)
        || coachCourses.some(item =>
            item.courseid === courseid
            && item.coachid === coach.coachid
        )
    );

    for (const coach of affectedCoaches) {
        // 儲存前重新查詢，保留教練目前的其他課程
        const currentCourses = await fetchCoursePageJson(
            `/api/coaches/${coach.coachid}/courses`
        );

        if (!Array.isArray(currentCourses)) {
            throw new Error(
                `教練 ${coach.name} 的課程資料格式不正確`
            );
        }

        const courseids = new Set(
            currentCourses.map(course => course.courseid)
        );

        if (selectedIds.has(coach.coachid)) {
            courseids.add(courseid);
        } else {
            courseids.delete(courseid);
        }

        await courseApiRequest(
            `/api/coaches/${coach.coachid}/courses`,
            "PUT",
            { courseids: [...courseids] }
        );
    }
}

const addCourseBtn = document.querySelector("#addCourseBtn");

if (addCourseBtn) {
    addCourseBtn.addEventListener("click", () => openCourseForm());

    document.querySelector("#courseForm").addEventListener(
        "submit",
        async event => {
            event.preventDefault();

            const form = event.currentTarget;
            const saveButton = form.querySelector(
                'button[type="submit"]'
            );

            // 避免重複送出
            if (saveButton.disabled) return;

            const formData = {
                coursename: document.querySelector(
                    "#courseName"
                ).value.trim(),

                coursetype: document.querySelector(
                    "#courseType"
                ).value,

                description: document.querySelector(
                    "#courseDescription"
                ).value.trim(),

                price: Number(
                    document.querySelector("#coursePrice").value
                )
            };

            if (!formData.coursename || !formData.coursetype) {
                alert("請填寫課程名稱與類型。");
                return;
            }

            if (
                !Number.isFinite(formData.price)
                || formData.price < 0
            ) {
                alert("價格必須是大於或等於 0 的數字。");
                return;
            }

            const isNew = editingCourseId === null;

            const desiredStatus = isNew
                ? "active"
                : document.querySelector("#courseStatus").value;

            const selectedCoachIds = [
                ...form.querySelectorAll(
                    'input[name="coachIds"]:checked'
                )
            ].map(checkbox => Number(checkbox.value));

            saveButton.disabled = true;

            let courseSaved = false;

            try {
                const savedCourse = await courseApiRequest(
                    isNew
                        ? "/api/courses"
                        : `/api/courses/${editingCourseId}`,
                    isNew ? "POST" : "PUT",
                    formData
                );

                if (!Number.isInteger(savedCourse?.courseid)) {
                    throw new Error(
                        "課程儲存回應缺少有效 ID，請重新整理列表確認結果，避免重複新增。"
                    );
                }

                courseSaved = true;

                // 新增後記住資料庫產生的 ID
                // 後續步驟失敗時，再按儲存會改用 PUT
                editingCourseId = savedCourse.courseid;

                document.querySelector(
                    "#courseModalTitle"
                ).textContent = "編輯課程";

                document.querySelector(
                    "#courseStatusGroup"
                ).hidden = false;

                document.querySelector(
                    "#courseStatus"
                ).value = desiredStatus;

                // 課程內容 PUT 不會修改狀態，因此另外呼叫 PATCH
                if (savedCourse.status !== desiredStatus) {
                    await courseApiRequest(
                        `/api/courses/${editingCourseId}/status`,
                        "PATCH",
                        { status: desiredStatus }
                    );
                }

                await saveCourseCoaches(
                    editingCourseId,
                    selectedCoachIds
                );

                bootstrap.Modal.getInstance(
                    document.querySelector("#courseModal")
                ).hide();

                alert("課程與授課教練已儲存成功！");

                await loadCourses();
            } catch (error) {
                console.error("課程儲存失敗：", error);

                alert(
                    courseSaved
                        ? `課程基本資料已儲存，但後續狀態或授課教練設定未全部完成：${error.message}\n請保留表單，確認後再按儲存。`
                        : error.message
                );
            } finally {
                saveButton.disabled = false;
            }
        }
    );
}

// null 表示新增；數字表示正在編輯的 coachid
let editingCoachId = null;

function renderCourseOptions(selectedCoachId = null) {
    const container = document.querySelector("#coachCourseOptions");
    container.replaceChildren();
    layoutCheckboxOptions(container, courses.length);


    courses.forEach(course => {
        const wrapper = document.createElement("div");
        wrapper.className = "form-check";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "form-check-input";
        checkbox.name = "courseIds";
        checkbox.value = course.courseid;
        checkbox.id = `courseOption${course.courseid}`;

        // 依資料庫回傳的專長還原勾選
        checkbox.checked = coachCourses.some(item =>
            item.coachid === selectedCoachId
            && item.courseid === course.courseid
        );

        const label = document.createElement("label");
        label.className = "form-check-label";
        label.htmlFor = checkbox.id;
        label.textContent = course.coursename;

        wrapper.append(checkbox, label);
        container.append(wrapper);
    });

    if (courses.length === 0) {
        container.textContent = "目前沒有課程，請先新增課程。";
    }
}

// 開啟新增或編輯教練的 Modal
function openCoachForm(coach = null) {
    const form = document.querySelector("#coachForm");
    form.reset();

    editingCoachId = coach?.coachid ?? null;

    document.querySelector("#coachModalTitle").textContent =
        coach ? "編輯教練" : "新增教練";

    document.querySelector("#coachNo").value = coach?.coachno ?? "";
    document.querySelector("#coachName").value = coach?.name ?? "";
    document.querySelector("#coachAccountId").value = coach?.accountid ?? "";

    const accountInput = document.querySelector("#coachAccountId");

    accountInput.readOnly = !!coach;
    accountInput.classList.toggle("bg-secondary-subtle", !!coach); document.querySelector("#coachGender").value = coach?.gender ?? "";

    document.querySelector("#coachPhone").value = coach?.phone ?? "";
    document.querySelector("#coachEmail").value = coach?.email ?? "";
    renderCourseOptions(editingCoachId);

    // 新增預設「在職」；編輯時才顯示狀態選單
    document.querySelector("#coachStatusGroup").hidden = !coach;
    document.querySelector("#coachStatus").value = coach?.status ?? "active";

    bootstrap.Modal.getOrCreateInstance(
        document.querySelector("#coachModal")
    ).show();
}

const addCoachBtn = document.querySelector("#addCoachBtn");

if (addCoachBtn) {
    addCoachBtn.addEventListener("click", () => openCoachForm());

    document.querySelector("#coachForm").addEventListener(
        "submit",
        async event => {
            event.preventDefault();

            const form = event.currentTarget;
            const saveButton = form.querySelector(
                'button[type="submit"]'
            );

            if (saveButton.disabled) return;

            const isNew = editingCoachId === null;

            const selectedCourseIds = [
                ...form.querySelectorAll(
                    'input[name="courseIds"]:checked'
                )
            ].map(checkbox => Number(checkbox.value));

            const specialty = courses
                .filter(course =>
                    selectedCourseIds.includes(course.courseid)
                )
                .map(course => course.coursename)
                .join("、");

            const formData = {
                coachno: document.querySelector(
                    "#coachNo"
                ).value.trim(),

                name: document.querySelector(
                    "#coachName"
                ).value.trim(),

                gender: document.querySelector(
                    "#coachGender"
                ).value.trim(),

                phone: document.querySelector(
                    "#coachPhone"
                ).value.trim(),

                email: document.querySelector(
                    "#coachEmail"
                ).value.trim(),

                specialty: specialty || null
            };

            if (!formData.coachno || !formData.name) {
                alert("請填寫教練編號與姓名。");
                return;
            }

            if (specialty.length > 200) {
                alert("所選課程名稱合計超過專長欄位的 200 字限制。");
                return;
            }

            // 只有新增需要傳入帳號 ID
            if (isNew) {
                const accountid = Number(
                    document.querySelector("#coachAccountId").value
                );

                if (!Number.isInteger(accountid) || accountid <= 0) {
                    alert("請輸入有效的帳號 ID。");
                    return;
                }

                formData.accountid = accountid;
            }

            const desiredStatus = isNew
                ? "active"
                : document.querySelector("#coachStatus").value;

            if (!["active", "inactive"].includes(desiredStatus)) {
                alert("教練狀態選項的 value 必須是 active 或 inactive。");
                return;
            }

            saveButton.disabled = true;
            let basicInfoSaved = false;

            try {
                // 1. 新增或修改基本資料
                const savedCoach = await courseApiRequest(
                    isNew
                        ? "/api/coaches"
                        : `/api/coaches/${editingCoachId}`,
                    isNew ? "POST" : "PUT",
                    formData
                );

                if (!Number.isInteger(savedCoach?.coachid)) {
                    throw new Error(
                        "儲存回應缺少有效教練 ID，請重新整理列表確認結果，避免重複新增。"
                    );
                }

                basicInfoSaved = true;
                editingCoachId = savedCoach.coachid;

                // 新增已完成，後續失敗重試時改用編輯 API
                document.querySelector(
                    "#coachModalTitle"
                ).textContent = "編輯教練";

                document.querySelector(
                    "#coachAccountId"
                ).readOnly = true;

                document.querySelector("#coachAccountId")
                    .classList.add("bg-secondary-subtle");

                document.querySelector(
                    "#coachStatusGroup"
                ).hidden = false;

                document.querySelector(
                    "#coachStatus"
                ).value = desiredStatus;

                // 2. 儲存教練狀態
                if (savedCoach.status !== desiredStatus) {
                    await courseApiRequest(
                        `/api/coaches/${editingCoachId}/status`,
                        "PATCH",
                        { status: desiredStatus }
                    );
                }

                // 3. 儲存完整的可授課程清單
                // 傳入空陣列代表清除這位教練所有課程關聯
                await courseApiRequest(
                    `/api/coaches/${editingCoachId}/courses`,
                    "PUT",
                    { courseids: selectedCourseIds }
                );

                bootstrap.Modal.getInstance(
                    document.querySelector("#coachModal")
                ).hide();

                alert(
                    isNew
                        ? "新增教練成功，可授課程已儲存！"
                        : "教練資料、狀態與可授課程已更新！"
                );

                await loadCoaches();
            } catch (error) {
                console.error("教練儲存失敗：", error);

                alert(
                    basicInfoSaved
                        ? `基本資料已儲存，但狀態或課程關聯未全部完成：${error.message}\n請保留表單，確認後再按儲存。`
                        : error.message
                );
            } finally {
                saveButton.disabled = false;
            }
        }
    );
}

// 讀取教練、課程及授課關聯
async function loadCoaches() {
    const addButton = document.querySelector("#addCoachBtn");

    if (addButton) addButton.disabled = true;

    try {
        const [coachList, courseList] = await Promise.all([
            fetchCoursePageJson("/api/coaches"),
            fetchCoursePageJson("/api/courses")
        ]);

        if (!Array.isArray(coachList) || !Array.isArray(courseList)) {
            throw new Error("教練或課程資料格式不是陣列");
        }

        const relationLists = await Promise.all(
            coachList.map(async coach => {
                const assignedCourses = await fetchCoursePageJson(
                    `/api/coaches/${coach.coachid}/courses`
                );

                if (!Array.isArray(assignedCourses)) {
                    throw new Error(
                        `教練 ${coach.name} 的課程格式不正確`
                    );
                }

                return assignedCourses.map(course => ({
                    coachid: coach.coachid,
                    courseid: course.courseid
                }));
            })
        );

        coaches = coachList;
        courses = courseList;
        coachCourses = relationLists.flat();

        renderCoaches();

        if (addButton) addButton.disabled = false;
    } catch (error) {
        console.error("讀取教練頁失敗：", error);

        const tbody = document.querySelector("#coachTableBody");

        if (tbody) {
            tbody.replaceChildren();
            const cell = tbody.insertRow().insertCell();
            cell.colSpan = 9;
            cell.textContent = "讀取失敗，請重新整理後再試。";
        }

        alert(error.message);
    }
}

// 讀取 API 的 JSON 資料
async function fetchCoursePageJson(url) {
    const response = await fetch(url);

    if (!response.ok) {
        throw new Error(
            `讀取失敗：${url}，狀態碼 ${response.status}`
        );
    }

    return response.json();
}

// 讀取課程、教練，以及真正的授課關聯
async function loadCourses() {
    const tbody = document.querySelector("#courseTableBody");
    const addButton = document.querySelector("#addCourseBtn");

    if (!tbody) return;

    addButton.disabled = true;
    tbody.replaceChildren();

    const loadingCell = tbody.insertRow().insertCell();
    loadingCell.colSpan = 9;
    loadingCell.textContent = "資料讀取中…";

    try {
        const [courseList, coachList] = await Promise.all([
            fetchCoursePageJson("/api/courses"),
            fetchCoursePageJson("/api/coaches")
        ]);

        if (!Array.isArray(courseList) || !Array.isArray(coachList)) {
            throw new Error("課程或教練列表的回傳格式不是陣列");
        }

        const relationLists = await Promise.all(
            coachList.map(async coach => {
                const assignedCourses = await fetchCoursePageJson(
                    `/api/coaches/${coach.coachid}/courses`
                );

                if (!Array.isArray(assignedCourses)) {
                    throw new Error(
                        `教練 ${coach.coachid} 的課程格式不是陣列`
                    );
                }

                return assignedCourses.map(course => ({
                    coachid: coach.coachid,
                    courseid: course.courseid
                }));
            })
        );

        // 全部讀取成功後，替換測試資料
        courses = courseList;
        coaches = coachList;
        coachCourses = relationLists.flat();

        renderCourses();

        addButton.disabled = false;
    } catch (error) {
        console.error("課程頁載入失敗：", error);

        tbody.replaceChildren();
        const cell = tbody.insertRow().insertCell();
        cell.colSpan = 9;
        cell.textContent = "資料讀取失敗，請確認後端及登入狀態。";

        alert(error.message);
    }
}

// 課程頁：讀取課程
if (document.querySelector("#courseTableBody")) {
    loadCourses();
}

// 教練頁：讀取教練
if (document.querySelector("#coachTableBody")) {
    loadCoaches();
}

// 輸入課程關鍵字時，重新篩選課程列表
document.querySelector("#courseSearch")
    ?.addEventListener("input", () => renderCourses());

// 輸入教練關鍵字時，重新篩選教練列表
document.querySelector("#coachSearch")
    ?.addEventListener("input", () => renderCoaches());