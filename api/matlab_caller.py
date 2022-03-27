import matlab.engine


def process_image(img_url, image_id):
    eng = matlab.engine.start_matlab()
    eng.diplom(img_url, image_id)
    eng.quit()
